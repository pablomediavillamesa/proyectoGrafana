#!/bin/bash
set -euo pipefail

log() {
    echo "[LOG - $(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "Actualizando sistema..."
sudo apt update -y

log "Instalando paquetes requeridos para Docker..."
sudo apt install -y ca-certificates curl gnupg lsb-release

log "Añadiendo clave GPG y repositorio de Docker..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

log "Instalando Docker Engine..."
sudo apt update -y
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

log "Habilitando Docker y añadiendo usuario ubuntu al grupo docker..."
sudo systemctl enable docker
sudo usermod -aG docker ubuntu

log "Docker instalado correctamente"
