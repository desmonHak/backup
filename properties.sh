#!/bin/bash

: '
Ejemplo de uso:
    
config.properties:
    database.host=localhost
    database.port=5432
    backup.path=/home/user/backups
    log.level=INFO

Uso:
load_properties "database.properties" "DB_"
load_properties "backup.properties"  "BK_"
load_properties "app.properties"     "APP_"

echo "Database: $DB_database_host"
echo "Backup:   $BK_backup_path"
echo "App:      $APP_log_level"
'
load_properties() {
    local prop_file=$1
    local prefix=${2:-""}  # Prefijo opcional para evitar conflictos
    
    if [ -f "$prop_file" ]; then
        while IFS='=' read -r key value || [ -n "$key" ]; do
            [[ $key =~ ^[[:space:]]*# || -z $key ]] && continue
            key=$(echo "$key" | tr -d '[:space:]' | tr '.' '_')
            value=$(echo "$value" | tr -d '[:space:]')
            export "${prefix}${key}=${value}"
        done < "$prop_file"
    fi
}

: '
Ejemplo de uso:
    
config.properties:
    database.host=localhost
    database.port=5432
    backup.path=/home/user/backups
    log.level=INFO

Uso:
load_properties "database.properties" "DB_"
load_properties "backup.properties"  "BK_"
load_properties "app.properties"     "APP_"

echo "Database: $DB_database_host"
echo "Backup:   $BK_backup_path"
echo "App:      $APP_log_level"

# Actualizar archivo específico
update_property "backup.properties" "backup.path" "/new/path"
update_property "database.properties" "database.port" "3306"

# Recargar solo el modificado
load_properties "backup.properties" "BK_"
echo "Nuevo backup path: $BK_backup_path"
'
update_property() {
    local prop_file=$1
    local key=$2
    local value=$3
    
    if grep -q "^$key=" "$prop_file" 2>/dev/null; then
        sed -i "s/^$key=.*/$key=$value/" "$prop_file"
    else
        echo "$key=$value" >> "$prop_file"
    fi
    echo "[$prop_file] $key = $value"
}
