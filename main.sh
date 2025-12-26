#!/bin/bash
#
# ===============================================================
#  Script de gestión de copias de seguridad (backup y restauración)
#  Autor: DesmonHak / versión 1.0
#  Descripción:
#    Permite realizar copias completas, diferenciales e
#    incrementales usando `tar`, además de restaurarlas
#    desde archivos comprimidos (.tar.gz).
# ===============================================================


# Carga funciones y utilidades para leer archivos .properties
source ./properties.sh

# Códigos ANSI y función de estilos para colores en consola
source ./colors.sh

# ---------------------------------------------------------------
# timestamp
# Devuelve la fecha y hora actual con formato YYYY-MM-DD_HH-MM-SS
# ---------------------------------------------------------------
timestamp() { date '+%Y-%m-%d_%H-%M-%S'; }

# ---------------------------------------------------------------
# ensure_dir <ruta>
# Crea el directorio indicado si no existe y muestra mensaje.
# --------------------------------------------------------------
ensure_dir() {
    local dir="$1"
    if mkdir -p "$dir" 2>/dev/null; then
        echo -e "$(style italic ${COLORS[LIGHT_GREEN]})✓ Creado: $dir${ENDCOLOR}"
    fi
}

# ---------------------------------------------------------------
# prompt_color <mensaje> <variable_destino>
# Muestra un mensaje con color ANSI y lee entrada del usuario.
# Sustituye `read -p`, que no interpreta colores.
# ---------------------------------------------------------------
prompt_color() {
    echo -ne "$1"
    read "$2"
}


# ---------------------------------------------------------------
# get_last_backup_file <tipo>
# Devuelve la ruta al archivo "meta" de control (p.ej. meta_full.txt)
# usado para almacenar la última copia de ese tipo.
# ---------------------------------------------------------------
get_last_backup_file() {
    local tipo="$1"
    echo "$backup_base_dir/meta_${tipo}.txt"
}

# ---------------------------------------------------------------
# validate_config
# Verifica que el archivo backup.properties exista y contenga
# las variables requeridas. También valida permisos de escritura.
# ---------------------------------------------------------------
validate_config() {
    load_properties "./backup.properties" "backup_"
    
    if [ -z "$backup_source_dir" ] || [ -z "$backup_base_dir" ]; then
        echo -e "$(style bold ${COLORS[RED]})Error: Faltan rutas en backup.properties${ENDCOLOR}"
        echo "Crea backup.properties con:"
        echo "backup_source_dir=/ruta/origen"
        echo "backup_base_dir=/ruta/backups"
        exit 1
    fi
    
    # Verificar permisos de escritura
    if [ ! -w "$(dirname "$backup_base_dir")" ]; then
        echo -e "$(style bold ${COLORS[RED]})Sin permisos de escritura en $(dirname "$backup_base_dir")${ENDCOLOR}"
        echo "Ejecuta: sudo chown $USER:$(id -gn) $(dirname "$backup_base_dir")"
        exit 1
    fi
    
    echo -e "$(style bold ${COLORS[GREEN]})Configuración OK${ENDCOLOR}"
    echo "Origen: $backup_source_dir"
    echo "Destino: $backup_base_dir"
}

# ---------------------------------------------------------------
# copia_completa
# Crea un backup completo del directorio fuente usando `tar`.
# Se guarda el snapshot (estado) para usar en futuras copias
# diferenciales o incrementales.
# ---------------------------------------------------------------
copia_completa() {
    echo -e "$(style bold ${COLORS[GREEN]})[COPIA COMPLETA]${ENDCOLOR}"
    ensure_dir "$backup_base_dir"

    local fecha=$(timestamp)
    local backup_file="$backup_base_dir/full_${fecha}.tar.gz"
    local snapshot="$backup_base_dir/snapshot_full.snar"

    echo -e "\n$(style italic ${COLORS[YELLOW]})Origen:${ENDCOLOR} $backup_source_dir"
    echo -e "$(style italic ${COLORS[YELLOW]})Destino:${ENDCOLOR} $backup_file"
    echo -e "$(style italic ${COLORS[YELLOW]})Creando copia completa... (modo verbose activado)${ENDCOLOR}\n"

    # Crea el archivo tar comprimido con registro incremental
    tar --listed-incremental="$snapshot" -cvzf "$backup_file" -C "$backup_source_dir" .
    local status=$?

    if [ $status -eq 0 ]; then
        echo "$backup_file" > "$(get_last_backup_file full)"
        echo -e "\n$(style bold ${COLORS[LIGHT_GREEN]})✓ Copia completa creada correctamente:${ENDCOLOR} $backup_file"
        echo -e "$(style italic ${COLORS[LIGHT_CYAN]})Archivos copiados desde:${ENDCOLOR} $backup_source_dir\n"
    else
        echo -e "\n$(style bold ${COLORS[RED]})Error al crear la copia completa (tar devolvió código $status)${ENDCOLOR}"
        [ -f "$backup_file" ] && rm -f "$backup_file"
    fi

    read -p "pulsa una tecla para continuar"
}


# ---------------------------------------------------------------
# copia_diferencial
# Crea un backup diferencial a partir del último snapshot completo.
# Copia sólo los archivos modificados desde la última copia completa.
# ---------------------------------------------------------------
copia_diferencial() {
    echo -e "$(style bold ${COLORS[YELLOW]})[COPIA DIFERENCIAL]${ENDCOLOR}"

    local snapshot_full="$backup_base_dir/snapshot_full.snar"
    if [ ! -f "$snapshot_full" ]; then
        echo -e "$(style bold ${COLORS[RED]})No hay copia completa previa.${ENDCOLOR}"
        return 1
    fi

    local fecha=$(timestamp)
    local backup_file="$backup_base_dir/diff_${fecha}.tar.gz"
    local snapshot_diff="$backup_base_dir/snapshot_diff.snar"

    echo -e "$(style italic ${COLORS[YELLOW]})Generando copia diferencial…${ENDCOLOR}"
    cp "$snapshot_full" "$snapshot_diff"
    tar --listed-incremental="$snapshot_diff" -cvzf "$backup_file" -C "$backup_source_dir" .
    local status=$?

    if [ $status -eq 0 ]; then
        echo "$backup_file" > "$(get_last_backup_file diff)"
        echo -e "$(style bold ${COLORS[LIGHT_GREEN]})✓ Copia diferencial creada correctamente: $backup_file${ENDCOLOR}"
    else
        echo -e "$(style bold ${COLORS[RED]})Error al crear copia diferencial (tar devolvió código $status)${ENDCOLOR}"
        [ -f "$backup_file" ] && rm -f "$backup_file"
    fi

    read -p "pulsa una tecla para continuar"
}

# ---------------------------------------------------------------
# copia_incremenental
# Crea un backup incremental. Usa el snapshot existente para
# copiar sólo los cambios desde la última copia (de cualquier tipo).
# ---------------------------------------------------------------
copia_incremenental() {
    echo -e "$(style bold ${COLORS[LIGHT_BLUE]})[COPIA INCREMENTAL]${ENDCOLOR}"

    local snapshot_inc="$backup_base_dir/snapshot_inc.snar"
    local fecha=$(timestamp)
    local backup_file="$backup_base_dir/inc_${fecha}.tar.gz"

    if [ ! -f "$snapshot_inc" ]; then
        cp "$backup_base_dir/snapshot_full.snar" "$snapshot_inc" 2>/dev/null || {
            echo -e "$(style bold ${COLORS[RED]})No hay copia completa previa.${ENDCOLOR}"
            return 1
        }
    fi

    echo -e "$(style italic ${COLORS[LIGHT_BLUE]})Generando copia incremental…${ENDCOLOR}"
    tar --listed-incremental="$snapshot_inc" -cvzf "$backup_file" -C "$backup_source_dir" .
    local status=$?

    if [ $status -eq 0 ]; then
        echo "$backup_file" > "$(get_last_backup_file inc)"
        echo -e "$(style bold ${COLORS[LIGHT_GREEN]})✓ Copia incremental creada correctamente: $backup_file${ENDCOLOR}"
    else
        echo -e "$(style bold ${COLORS[RED]})Error al crear la copia incremental (tar devolvió código $status)${ENDCOLOR}"
        [ -f "$backup_file" ] && rm -f "$backup_file"
    fi

    read -p "pulsa una tecla para continuar"
}

# ---------------------------------------------------------------
# restaurar_backup
# Permite listar todas las copias disponibles (.tar.gz) y restaurar
# una seleccionada por el usuario en un destino determinado.
# ---------------------------------------------------------------
restaurar_backup() {
    echo -e "$(style bold ${COLORS[LIGHT_GREEN]})[RESTAURAR COPIA DE SEGURIDAD]${ENDCOLOR}"

    # Buscar archivos de backup en el directorio
    local archivos=("$backup_base_dir"/*.tar.gz)

    # Verificar si existen copias
    if [ ${#archivos[@]} -eq 0 ] || [ ! -e "${archivos[0]}" ]; then
        echo -e "$(style bold ${COLORS[RED]})No hay copias disponibles para restaurar.${ENDCOLOR}"
        sleep 2
        return
    fi

    echo -e "\n$(style italic ${COLORS[LIGHT_CYAN]})Copias disponibles:${ENDCOLOR}"
    for i in "${!archivos[@]}"; do
        echo -e "$(style bold ${COLORS[MAGENTA]})$((i+1))${ENDCOLOR}) ${archivos[$i]}"
    done

    prompt_color "$(style bold ${COLORS[WHITE]})Selecciona el número de la copia a restaurar: ${ENDCOLOR}" seleccion

    # Validar la selección
    if ! [[ "$seleccion" =~ ^[0-9]+$ ]] || [ "$seleccion" -lt 1 ] || [ "$seleccion" -gt "${#archivos[@]}" ]; then
        echo -e "$(style bold ${COLORS[RED]})Selección inválida.${ENDCOLOR}"
        sleep 2
        return
    fi

    local archivo="${archivos[$((seleccion-1))]}"
    echo -e "\n$(style italic ${COLORS[YELLOW]})Seleccionado:${ENDCOLOR} $archivo"
    read -p "¿Dónde quieres restaurar los archivos? [ruta destino]: " destino

    # Validar destino
    [ -z "$destino" ] && { echo "Ruta destino vacía, cancelando."; sleep 2; return; }
    ensure_dir "$destino"

    echo -e "$(style italic ${COLORS[LIGHT_BLUE]})Restaurando en modo verbose...${ENDCOLOR}"
    tar -xvzf "$archivo" -C "$destino"
    local status=$?

    if [ $status -eq 0 ]; then
        echo -e "$(style bold ${COLORS[LIGHT_GREEN]})✓ Copia restaurada correctamente en:${ENDCOLOR} $destino"
    else
        echo -e "$(style bold ${COLORS[RED]})Error al restaurar copia (tar devolvió código $status)${ENDCOLOR}"
    fi

    sleep 3
}



menu() {
    validate_config # validar conf de backup.properties

    load_properties "./version.properties" "version_"

    while true; do
        clear


        echo -e "=== $(style blink ${COLORS[WHITE]})MENÚ PRINCIPAL${ENDCOLOR} ==="
        echo -e "$(style bold ${COLORS[MAGENTA]})1${ENDCOLOR}) $(style italic ${COLORS[LIGHT_CYAN]})Copia completa${ENDCOLOR}"
        echo -e "$(style bold ${COLORS[MAGENTA]})2${ENDCOLOR}) $(style italic ${COLORS[LIGHT_CYAN]})Copia diferencial${ENDCOLOR}"
        echo -e "$(style bold ${COLORS[MAGENTA]})3${ENDCOLOR}) $(style italic ${COLORS[LIGHT_CYAN]})Copia incremental${ENDCOLOR}"
        echo -e "$(style bold ${COLORS[MAGENTA]})4${ENDCOLOR}) $(style italic ${COLORS[LIGHT_GREEN]})Restaurar una copia${ENDCOLOR}"
        echo -e "$(style bold ${COLORS[MAGENTA]})0${ENDCOLOR}) $(style italic ${COLORS[LIGHT_CYAN]})Salir${ENDCOLOR}"
        echo -e "====================="

        echo -e "autor: $version_project_author"
        echo -e "github: $version_project_github"
        echo -e "version: $version_project_version\n"

        read -p "Introduce una opción: " opcion
        
        case $opcion in
            1) copia_completa ;;
            2) copia_diferencial ;;
            3) copia_incremenental ;;
            4) restaurar_backup ;;
            0) echo "¡Saliendo!"; exit 0 ;;
            *) echo "Opción inválida"; sleep 1 ;;
        esac
    done
}

: '
    "BASH_VERSION": Variable de entorno que bash define automáticamente
    con su versión (ej: "5.1.16"). :
    Ejecutado con bash	    "5.1.16(1)-release"	    true
    Ejecutado con sh (dash)	Vacía ("")	            false
'
# Comprobación de privilegios y shell
if [ -z "$BASH_VERSION" ]; then
    echo "Debe ejecutarse usando bash"
    exit 1
fi

if [ "$EUID" -ne 0 ]; then
    echo "Debe ejecutarse como root o con sudo"
    echo "Ejemplo: sudo ./main.sh"
    exit 1
fi

# Si las comprobaciones son correctas, continúar al menu principal
menu
