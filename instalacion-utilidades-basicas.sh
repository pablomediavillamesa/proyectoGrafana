#!/bin/bash

echo "Actualizando repositorios..."
sudo apt update && sudo apt upgrade -y

echo "Instalando utilidades básicas..."
sudo apt install -y \
  tree \             # visualiza estructuras de carpetas
  tldr \             # versiones resumidas de man pages
  htop \             # monitor de procesos interactivo
  curl \             # peticiones HTTP desde CLI
  net-tools          # utilidades de red como ifconfig

echo "Instalación completa. Ejecuta 'tldr' una vez para inicializar su base de datos."
