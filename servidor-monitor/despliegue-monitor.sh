#!/bin/bash
set -euo pipefail

# === LOGGING ===
LOG_FILE="/var/log/despliegue-monitor.log"
exec > >(tee -a "$LOG_FILE") 2>&1

log() {
    echo "[LOG - $(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# === MOVERSE AL DIRECTORIO DEL SCRIPT ===
cd "$(dirname "$0")"

# === RUTAS DE SCRIPTS ===
DOCKER_SCRIPT="./instalacion-docker.sh"
NODE_EXPORTER_SCRIPT="./node-exporter-install.sh"
DOCKER_COMPOSE_FILE="./docker-compose.yml"
DNS_SCRIPT="./dns.sh"

# === FUNCIONES DE UTILIDAD ===
check_file() {
    if [[ ! -f "$1" ]]; then
        log "[ERROR] Archivo no encontrado: $1"
        exit 1
    fi
}

check_exec() {
    if [[ ! -x "$1" ]]; then
        log "[WARN] $1 no era ejecutable. Aplicando chmod +x"
        chmod +x "$1" || {
            log "[ERROR] No se pudo hacer ejecutable: $1"
            exit 1
        }
    fi
}

# === EJECUCIÓN PRINCIPAL ===
main() {
    log "Verificando scripts..."
    check_file "$DOCKER_SCRIPT"
    check_exec "$DOCKER_SCRIPT"
    check_file "$NODE_EXPORTER_SCRIPT"
    check_exec "$NODE_EXPORTER_SCRIPT"
    log "Ejecutando script de instalación de Docker..."
    "$DOCKER_SCRIPT"
    log "Ejecutando script de instalación de Node Exporter..."
    "$NODE_EXPORTER_SCRIPT"

    if [[ -f "$DOCKER_COMPOSE_FILE" ]]; then
        log "Levantando contenedores con Docker Compose..."
        sudo docker compose up -d
    else
        log "[WARN] docker-compose.yml no encontrado, se omite docker compose up"
    fi

    # === EJECUTAR DNS.sh AL FINAL ===
    check_file "$DNS_SCRIPT"
    check_exec "$DNS_SCRIPT"
    log "Ejecutando script de actualización DuckDNS..."
    "$DNS_SCRIPT"
    if [[ $? -eq 0 ]]; then
        log "[OK] dns.sh ejecutado correctamente"
    else
        log "[ERROR] Falló la ejecución de dns.sh"
        exit 1
    fi

    log "Despliegue completado correctamente"
}

main "$@"
