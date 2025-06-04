#!/bin/bash

# Variables
MYSQL_ROOT_PASSWORD="admin"
MYSQL_USER="pablom"
MYSQL_PASSWORD="pablom"
MYSQL_DATABASE="monitoring"
MYSQL_BIND_ADDRESS="0.0.0.0"

echo "🔧 Instalando MySQL Server..."
sudo apt update
sudo apt install -y mysql-server

echo "🔧 Configurando MySQL para aceptar conexiones remotas..."
sudo sed -i "s/^bind-address.*/bind-address = $MYSQL_BIND_ADDRESS/" /etc/mysql/mysql.conf.d/mysqld.cnf

echo "🔧 Reiniciando MySQL..."
sudo systemctl restart mysql.service
sudo systemctl enable mysql.service

echo "🔒 Configurando seguridad de MySQL..."
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASSWORD'; FLUSH PRIVILEGES;"

echo "👤 Creando usuario remoto '$MYSQL_USER'..."
sudo mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';"
sudo mysql -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'%' WITH GRANT OPTION; FLUSH PRIVILEGES;"

echo "🗃️ Creando base de datos '$MYSQL_DATABASE' y tablas..."
sudo mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE DATABASE IF NOT EXISTS $MYSQL_DATABASE CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -u root -p$MYSQL_ROOT_PASSWORD $MYSQL_DATABASE <<EOF
CREATE TABLE IF NOT EXISTS metrics (
    id INT AUTO_INCREMENT PRIMARY KEY,
    event_time DATETIME NOT NULL,
    game VARCHAR(20) NOT NULL,
    event_type VARCHAR(20) NOT NULL,
    score INT
);

CREATE TABLE IF NOT EXISTS metrics_likes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    event_time DATETIME NOT NULL,
    game VARCHAR(20) NOT NULL,
    reaction_type VARCHAR(20) NOT NULL
);
EOF

echo "🌐 Añadiendo regla al firewall para permitir conexiones a MySQL (puerto 3306)..."
sudo ufw allow 3306

echo "✅ MySQL instalado, configurado y listo para conexiones remotas en $MYSQL_BIND_ADDRESS."
echo "🔑 Acceso remoto: Host=tu_IP, Usuario=$MYSQL_USER, Contraseña=$MYSQL_PASSWORD, Base de datos=$MYSQL_DATABASE