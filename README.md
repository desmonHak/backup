# Bakcup

----

Este script permite crear y restaurar copias de seguridad desde la línea de comandos usando tar.
Funciona en entornos Linux/macOS y ofrece tres tipos de copia:

    Copia completa – Guarda todos los archivos.

    Copia diferencial – Solo modifica desde la última completa.

    Copia incremental – Solo modifica desde la última copia, sea cual sea.

También permite restaurar copias anteriores en una carpeta destino.

----

## Dependencias

El script requiere estas utilidades estándar de Linux:
    - bash ≥ 5.0
    - tar
    - mkdir, cp, rm, sleep
    - sudo (para ejecución con privilegios)

----

## Estructura del proyecto

```
backup/
├── main.sh                # Script principal
├── colors.sh              # Utilidades para colores y estilos
├── properties.sh          # Lector de archivos .properties
├── backup.properties      # Configuración de rutas
└── version.properties     # Datos del proyecto
```

----

## Configuración

Crea el archivo backup.properties (si no existe):
```
backup_source_dir=./        # Carpeta con los archivos que quieres respaldar
backup_base_dir=./backups   # Carpeta donde se guardarán las copias
```

Y el archivo version.properties:
```
project.author=Tu nombre
project.github=https://github.com/tu_usuario
project.version=1.0
```

----

## Ejecución

El script requiere permisos de root o sudo para asegurar el acceso a todas las rutas.

```shell
sudo ./main.sh
```

----

## Menú principal

Al ejecutarlo, verás:
```
=== MENÚ PRINCIPAL ===
1) Copia completa
2) Copia diferencial
3) Copia incremental
4) Restaurar copia
0) Salir
======================
```

----

### 1. Copia completa

Crea un archivo .tar.gz con todo el contenido de la carpeta origen.

```
[~] Copia completa
Origen: ./documentos
Destino: ./backups/full_2025-12-26_21-16-34.tar.gz
```
Usa la opción ``--listed-incremental`` de tar para registrar el estado del sistema.

----

### 2. Copia diferencial

Copia solo los archivos modificados desde la última copia completa.

Genera diff_YYYY-MM-DD_HH-MM-SS.tar.gz.



    Requiere haber hecho al menos una copia completa.

----

### 3. Copia incremental

Copia solo los cambios ocurridos desde la última copia (completa o incremental).
Ideal para sistemas con respaldo frecuente.

Usa automáticamente snapshots (.snar) para registrar los cambios del sistema de archivos.

----

## Restaurar copias

La opción 4) permite listar todas las copias disponibles (.tar.gz) en la ruta de backup:

```
[RESTAURAR COPIA DE SEGURIDAD]
1) ./backups/full_2025-12-26_21-20-00.tar.gz
2) ./backups/inc_2025-12-27_10-32-12.tar.gz
```

Luego pide la ruta destino para extraer:
```
Ruta destino: ./restauracion
Restaurando en modo verbose...
✓ Copia restaurada correctamente en: ./restauracion
```

-----

# Archivos generados

| Tipo        | Formato de nombre                      | Descripción                              |
|--------------|----------------------------------------|------------------------------------------|
| Completa     | full_YYYY-MM-DD_HH-MM-SS.tar.gz        | Copia total del origen                   |
| Diferencial  | diff_YYYY-MM-DD_HH-MM-SS.tar.gz        | Cambios desde la última completa         |
| Incremental  | inc_YYYY-MM-DD_HH-MM-SS.tar.gz         | Cambios desde la última copia            |
| Meta         | meta_full.txt, meta_diff.txt, meta_inc.txt | Registran la última copia de cada tipo   |
| Snapshots    | snapshot_full.snar, snapshot_diff.snar, snapshot_inc.snar | Control de cambios para tar |



# Consejos

Agrega ``alias backup='sudo ./main.sh'`` en tu ``~/.bashrc`` para ejecutar rápidamente.

Puedes programar una copia automática con cron:
```shell
sudo crontab -e
```

Y añadir, por ejemplo, para una copia completa diaria a las 2 AM:
```shell
0 2 * * * /ruta/a/main.sh > /var/log/backup_diario.log 2>&1
```

----
