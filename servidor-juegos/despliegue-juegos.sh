#!/bin/bash
set -euo pipefail

# === LOGGING ===
LOG_FILE="/var/log/despliegue-app.log"
exec > >(tee -a "$LOG_FILE") 2>&1

log() {
    echo "[LOG - $(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# === RUTAS Y CONFIGURACIÓN ===
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APACHE_SCRIPT="$ROOT_DIR/apache/apache.sh"
NODE_EXPORTER_SCRIPT="$ROOT_DIR/node-exporter-install.sh"
APACHE_CONF_SRC="$ROOT_DIR/apache/000-default.conf"
APACHE_CONF_DEST="/etc/apache2/sites-available/000-default.conf"
TFG_WEB_SRC="$ROOT_DIR/tfgweb"
TFG_WEB_DEST="/var/www/tfgweb"
CRON_FILE="/etc/cron.d/metrics_db_cron"
CRON_CMD="/usr/bin/php $ROOT_DIR/sql_export/metrics-to-db.php"
METRICS_GENERATOR="$ROOT_DIR/metrics-generator.sh"

# === COMPROBAR ROOT ===
require_root() {
    if [[ "$EUID" -ne 0 ]]; then
        log "[ERROR] Este script debe ejecutarse como root"
        exit 1
    fi
}

# === VERIFICAR EXISTENCIA Y PERMISOS DE SCRIPTS Y ARCHIVOS ===
check_file() {
    if [[ ! -f "$1" ]]; then
        log "[ERROR] Archivo no encontrado: $1"
        exit 1
    fi
}

check_exec() {
    if [[ ! -f "$1" ]]; then
        log "[ERROR] Script no encontrado: $1"
        exit 1
    fi
    if [[ ! -x "$1" ]]; then
        log "[WARN] $1 no era ejecutable. Aplicando chmod +x"
        chmod +x "$1" || {
            log "[ERROR] No se pudo hacer ejecutable: $1"
            exit 1
        }
    fi
}

# === INSTALAR APACHE ===
install_apache() {
    check_exec "$APACHE_SCRIPT"
    log "[INFO] Ejecutando script de instalación de Apache"
    "$APACHE_SCRIPT"
}

# === INSTALAR NODE EXPORTER ===
install_node_exporter() {
    check_exec "$NODE_EXPORTER_SCRIPT"
    log "[INFO] Ejecutando script de instalación de Node Exporter"
    "$NODE_EXPORTER_SCRIPT"
}

# === REEMPLAZAR CONFIG DE APACHE ===
replace_apache_conf() {
    check_file "$APACHE_CONF_SRC"
    log "[INFO] Reemplazando configuración de Apache"
    cp "$APACHE_CONF_SRC" "$APACHE_CONF_DEST"
    systemctl reload apache2 || log "[WARN] Apache no se recargó correctamente"
}

# === DESPLEGAR WEB ===
deploy_web() {
    if [[ ! -d "$TFG_WEB_SRC" ]]; then
        log "[ERROR] Carpeta web no encontrada: $TFG_WEB_SRC"
        exit 1
    fi
    log "[INFO] Desplegando archivos de la aplicación web"
    mkdir -p "$TFG_WEB_DEST"
    rsync -a --delete "$TFG_WEB_SRC"/ "$TFG_WEB_DEST"/
    chown -R www-data:www-data "$TFG_WEB_DEST"
}

# === CONFIGURAR CRON PARA EXPORT A BD ===
setup_cron() {
    log "[INFO] Configurando cron para exportar métricas a base de datos"
    echo "*/30 * * * * root $CRON_CMD >/dev/null 2>&1" > "$CRON_FILE"
    chmod 644 "$CRON_FILE"
}

# === EJECUTAR GENERADOR MÉTRICAS EN BACKGROUND ===
run_generator() {
    check_exec "$METRICS_GENERATOR"
    log "[INFO] Ejecutando metrics-generator en segundo plano"
    nohup "$METRICS_GENERATOR" >> "$LOG_FILE" 2>&1 &
    disown
}

# === MAIN ===
main() {
    log "[INICIO] Despliegue iniciado"
    require_root
    install_apache
    install_node_exporter
    replace_apache_conf
    deploy_web
    setup_cron
    run_generator
    log "[FIN] Despliegue completado correctamente"
}

main "$@"
