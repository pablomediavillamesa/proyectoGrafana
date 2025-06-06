#!/bin/bash

### ==== CONFIGURACIÓN MANUAL ====
DOMINIO="pg-servidor-juegos.duckdns.org"           # <--- Cambia por tu dominio
EMAIL="mediavillap13@gmail.com"      # <--- Cambia por tu email (para avisos de renovación)
INCLUDE_WWW=0        # 1 para añadir www, 0 para NO añadir www
### ==============================

DIRDISTRO="unknown"
if [ -f /etc/debian_version ]; then
  DIRDISTRO="debian"
elif [ -f /etc/redhat-release ]; then
  DIRDISTRO="redhat"
fi

# Comprobar root
if [ "$EUID" -ne 0 ]; then
  echo "Debes ejecutar este script como root o usando sudo."
  exit 1
fi

# Instalar Apache si no está
if ! command -v apache2 >/dev/null 2>&1 && ! command -v httpd >/dev/null 2>&1; then
  echo "Instalando Apache..."
  if [ "$DIRDISTRO" = "debian" ]; then
    apt update && apt install -y apache2
  elif [ "$DIRDISTRO" = "redhat" ]; then
    dnf install -y httpd || yum install -y httpd
    systemctl enable httpd
    systemctl start httpd
  else
    echo "Distribución no soportada automáticamente. Instala Apache manualmente."
    exit 1
  fi
fi

# Instalar Certbot y plugin Apache
echo "Instalando Certbot y plugin Apache..."
if [ "$DIRDISTRO" = "debian" ]; then
  apt update
  apt install -y certbot python3-certbot-apache
elif [ "$DIRDISTRO" = "redhat" ]; then
  dnf install -y certbot python3-certbot-apache || yum install -y certbot python3-certbot-apache
else
  echo "No se reconoce la distribución, instala Certbot manualmente."
  exit 1
fi

# Construir lista de dominios
DOMINIOS="-d $DOMINIO"
if [ "$INCLUDE_WWW" = "1" ]; then
  DOMINIOS="$DOMINIOS -d www.$DOMINIO"
fi

EMAIL_OPT="--email $EMAIL --agree-tos"

# Solicitar el certificado
echo "Solicitando el certificado para: $DOMINIOS"
certbot --apache $DOMINIOS $EMAIL_OPT --non-interactive

RETVAL=$?
if [ $RETVAL -eq 0 ]; then
  echo "Certificado instalado correctamente para $DOMINIO"
else
  echo "Hubo un problema al solicitar el certificado. Consulta la salida anterior."
  exit 2
fi

# Prueba de renovación automática
echo "Comprobando la renovación automática..."
certbot renew --dry-run

echo "==================================="
echo "¡Configuración Let's Encrypt finalizada!"
echo "Tu sitio debe estar disponible en https://$DOMINIO/"
echo "Renovación automática configurada por defecto."
echo "==================================="
