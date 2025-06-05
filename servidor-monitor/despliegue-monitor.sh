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

restaurar_volumen() {
    local VOLUMEN="$1"
    local ARCHIVO="$2"
    if [[ -f "$ARCHIVO" ]]; then
        log "Restaurando volumen Docker '$VOLUMEN' desde '$ARCHIVO'..."
        docker volume inspect "$VOLUMEN" >/dev/null 2>&1 || docker volume create "$VOLUMEN"
        docker run --rm -v "$VOLUMEN":/data -v "$(dirname "$ARCHIVO")":/backup busybox sh -c "cd /data && tar xzf /backup/$(basename "$ARCHIVO")"
        log "Volumen '$VOLUMEN' restaurado correctamente."
    else
        log "[WARN] No se encontró el backup '$ARCHIVO' para el volumen '$VOLUMEN', se omite restauración."
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

    # === Restaurar volúmenes desde backups comprimidos ===
    VOLUMES_DIR="./volumes"
    restaurar_volumen "alertmanager_data" "$VOLUMES_DIR/backup_alertmanager_data.tar.gz"
    restaurar_volumen "grafana_data" "$VOLUMES_DIR/backup_grafana_data.tar.gz"

    if [[ -f "$DOCKER_COMPOSE_FILE" ]]; then
        log "Levantando contenedores con Docker Compose..."
        sudo docker compose up -d
    else
        log "[WARN] docker-compose.yml no encontrado, se omite docker compose up"
    fi
    log "Despliegue completado correctamente"
}

main "$@"
