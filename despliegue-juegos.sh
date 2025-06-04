#!/bin/bash

set -euo pipefail

# === RUTAS Y CONFIGURACIÓN ===
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APACHE_SCRIPT="$ROOT_DIR/apache/apache.sh"
NODE_EXPORTER_SCRIPT="$ROOT_DIR/node-exporter-install.sh"
APACHE_CONF_SRC="$ROOT_DIR/apache/000-default.conf"
APACHE_CONF_DEST="/etc/apache2/sites-available/000-default.conf"
TFG_WEB_SRC="$ROOT_DIR/tfgweb"
TFG_WEB_DEST="/var/www/html/tfgweb"
CRON_FILE="/etc/cron.d/metrics_db_cron"
CRON_CMD="/usr/bin/php $ROOT_DIR/sql_export/metrics-to-db.php"
METRICS_GENERATOR="$ROOT_DIR/metrics-generator.sh"

# === COMPROBAR ROOT ===
require_root() {
    [[ "$EUID" -ne 0 ]] && printf "[ERROR] Ejecutar como root\n" >&2 && return 1
}

# === VERIFICAR EXISTENCIA Y PERMISOS DE SCRIPTS Y ARCHIVOS ===
check_exec() { [[ ! -x "$1" ]] && printf "[ERROR] No ejecutable: %s\n" "$1" >&2 && return 1; }
check_file() { [[ ! -f "$1" ]] && printf "[ERROR] No encontrado: %s\n" "$1" >&2 && return 1; }

# === INSTALAR APACHE ===
install_apache() {
    check_exec "$APACHE_SCRIPT" || return 1
    "$APACHE_SCRIPT" || return 1
}

# === INSTALAR NODE EXPORTER ===
install_node_exporter() {
    check_exec "$NODE_EXPORTER_SCRIPT" || return 1
    "$NODE_EXPORTER_SCRIPT" || return 1
}

# === REEMPLAZAR CONFIG DE APACHE ===
replace_apache_conf() {
    check_file "$APACHE_CONF_SRC" || return 1
    cp "$APACHE_CONF_SRC" "$APACHE_CONF_DEST" || return 1
    systemctl reload apache2 || printf "[WARN] Apache no recargado\n" >&2
}

# === COPIAR CARPETA WEB AL DIRECTORIO DE APACHE ===
deploy_web() {
    [[ ! -d "$TFG_WEB_SRC" ]] && printf "[ERROR] Carpeta web no encontrada\n" >&2 && return 1
    mkdir -p "$TFG_WEB_DEST"
    rsync -a --delete "$TFG_WEB_SRC"/ "$TFG_WEB_DEST"/ || return 1
    chown -R www-data:www-data "$TFG_WEB_DEST"
}

# === CREAR CRON QUE EJECUTA PHP CADA 30 MINUTOS ===
setup_cron() {
    printf "*/30 * * * * root $CRON_CMD >/dev/null 2>&1\n" > "$CRON_FILE"
    chmod 644 "$CRON_FILE"
}

# === EJECUTAR GENERADOR DE MÉTRICAS EN BACKGROUND ===
run_generator() {
    check_exec "$METRICS_GENERATOR" || return 1
    nohup "$METRICS_GENERATOR" >/dev/null 2>&1 & disown
}

# === MAIN ===
main() {
    require_root || exit 1
    printf "[INFO] Instalando Apache...\n"; install_apache || exit 1
    printf "[INFO] Instalando Node Exporter...\n"; install_node_exporter || exit 1
    printf "[INFO] Configurando Apache...\n"; replace_apache_conf || exit 1
    printf "[INFO] Desplegando Web...\n"; deploy_web || exit 1
    printf "[INFO] Configurando Cron...\n"; setup_cron || exit 1
    printf "[INFO] Ejecutando metrics-generator.sh...\n"; run_generator || exit 1
    printf "[✓] Despliegue completado\n"
}

main "$@"
