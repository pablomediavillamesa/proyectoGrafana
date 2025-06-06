#!/bin/bash

# Configura aquí tu dominio y token de DuckDNS
DOMINIO="pg-servidor-juegos"
TOKEN="8c9b04da-db3c-4513-9d00-a5ae7356bc91"
DIR="$HOME/duckdns"
SCRIPT="$DIR/duck.sh"
LOG="$DIR/duck.log"
CRONLINE="*/5 * * * * $SCRIPT >/dev/null 2>&1"

echo "=== Comprobando e instalando dependencias ==="

# Detectar distribución
if [ -f /etc/debian_version ]; then
  DISTRO="debian"
elif [ -f /etc/redhat-release ]; then
  DISTRO="redhat"
else
  DISTRO="other"
fi

# Instalar curl si no existe
if ! command -v curl >/dev/null 2>&1; then
  echo "Instalando curl..."
  if [ "$DISTRO" = "debian" ]; then
    sudo apt update && sudo apt install -y curl
  elif [ "$DISTRO" = "redhat" ]; then
    sudo dnf install -y curl || sudo yum install -y curl
  else
    echo "Instala curl manualmente y vuelve a ejecutar el script."
    exit 1
  fi
else
  echo "curl ya está instalado."
fi

# Instalar cron si no existe
if ! pgrep -x "cron" >/dev/null && ! pgrep -x "crond" >/dev/null; then
  echo "Instalando y arrancando cron..."
  if [ "$DISTRO" = "debian" ]; then
    sudo apt update && sudo apt install -y cron
    sudo systemctl enable cron
    sudo systemctl start cron
  elif [ "$DISTRO" = "redhat" ]; then
    sudo dnf install -y cronie || sudo yum install -y cronie
    sudo systemctl enable crond
    sudo systemctl start crond
  else
    echo "Instala cron manualmente y vuelve a ejecutar el script."
    exit 1
  fi
else
  echo "cron ya está instalado y/o ejecutándose."
fi

echo "=== Preparando carpeta y script de DuckDNS ==="
mkdir -p "$DIR"
cat > "$SCRIPT" << EOF
#!/bin/bash
echo url="https://www.duckdns.org/update?domains=$DOMINIO&token=$TOKEN&ip=" | \\
curl -k -o "$LOG" -K -
EOF
chmod 700 "$SCRIPT"

echo "=== Configurando tarea en cron ==="
# Comprobar si ya está en crontab
( crontab -l 2>/dev/null | grep -q "$SCRIPT" ) || (
  ( crontab -l 2>/dev/null; echo "$CRONLINE" ) | crontab -
  echo "Línea añadida a crontab"
)

echo "=== Ejecutando una prueba inicial ==="
"$SCRIPT"
echo "Resultado del log:"
cat "$LOG"

echo "=== Proceso finalizado ==="
echo "El script actualizará tu IP cada 5 minutos."
echo "Si quieres cambiar dominio/token, edítalos en el propio dns.sh antes de volver a ejecutarlo."
