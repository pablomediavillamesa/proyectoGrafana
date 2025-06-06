#!/bin/bash
set -e

# Variables
NODE_EXPORTER_DIR="/tmp/node_exporter"
NODE_EXPORTER_USER="nobody"

echo "Clonando el repositorio oficial de Node Exporter..."
git clone https://github.com/prometheus/node_exporter.git $NODE_EXPORTER_DIR
cd $NODE_EXPORTER_DIR

echo "Instalando dependencias necesarias (Go)..."
sudo apt update
sudo apt install -y golang git make

echo "Compilando Node Exporter..."
make build

echo "Instalando Node Exporter en /usr/local/bin..."
sudo cp $NODE_EXPORTER_DIR/node_exporter /usr/local/bin/
sudo chown root:root /usr/local/bin/node_exporter
sudo chmod 755 /usr/local/bin/node_exporter

echo "Creando servicio systemd para Node Exporter..."
sudo bash -c 'cat > /etc/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=nobody
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF'

echo "Habilitando y arrancando Node Exporter..."
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
sudo systemctl status node_exporter --no-pager

echo "Node Exporter instalado y corriendo en :9100"
