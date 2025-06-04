#!/bin/bash

echo "🔧 Dando permisos de ejecución a los scripts..."
chmod +x instalacion-docker.sh
chmod +x node-exporter-install.sh

echo "🚀 Ejecutando scripts de instalación..."
./instalacion-docker.sh
./node-exporter-install.sh

echo "🐳 Levantando contenedores con Docker Compose..."