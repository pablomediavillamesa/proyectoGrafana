#!/bin/bash

echo "Actualizando repositorios..."
sudo apt update && sudo apt upgrade -y

echo "Instalando utilidades básicas..."
sudo apt install -y tree tldr htop curl net-tools

echo "Instalación completa. Ejecuta 'tldr' una vez para inicializar su base de datos."
