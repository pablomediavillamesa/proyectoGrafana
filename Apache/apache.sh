#!/bin/bash

# Variables de configuración
DB_ROOT_PASSWORD="rootpass"
DB_NAME="wordpress"
DB_USER="wp_user"
DB_PASSWORD="wp_pass"
WP_DIR="/var/www/html/wordpress"

echo "Actualizando sistema..."
sudo apt update && sudo apt upgrade -y

echo "Instalando Apache, PHP y MariaDB..."
sudo apt install -y apache2 mariadb-server php php-mysql php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip unzip wget

echo "Habilitando Apache y MariaDB..."
sudo systemctl enable --now apache2
sudo systemctl enable --now mariadb

echo "Configurando base de datos de WordPress..."
sudo mysql -e "CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
sudo mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "Descargando WordPress..."
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
sudo mv wordpress $WP_DIR
sudo rm latest.tar.gz

echo "Configurando permisos..."
sudo chown -R www-data:www-data $WP_DIR
sudo find $WP_DIR -type d -exec chmod 755 {} \;
sudo find $WP_DIR -type f -exec chmod 644 {} \;

echo "Configurando wp-config.php..."
cp $WP_DIR/wp-config-sample.php $WP_DIR/wp-config.php
sed -i "s/database_name_here/${DB_NAME}/" $WP_DIR/wp-config.php
sed -i "s/username_here/${DB_USER}/" $WP_DIR/wp-config.php
sed -i "s/password_here/${DB_PASSWORD}/" $WP_DIR/wp-config.php

echo "Reiniciando Apache..."
sudo systemctl restart apache2

echo "Instalación completada. Accede a http://<IP_DEL_SERVIDOR>/wordpress para finalizar la instalación de WordPress desde el navegador."
