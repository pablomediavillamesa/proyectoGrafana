#!/bin/bash

sudo apt update
sudo apt install -y apache2 libapache2-mod-php8.3 php8.3 php8.3-mysql php8.3-xml php8.3-mbstring php8.3-curl php8.3-gd
sudo systemctl enable apache2
sudo systemctl restart apache2

