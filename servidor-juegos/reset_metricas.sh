#!/bin/bash

# Definir rutas de los archivos
LOG_FILE="/var/www/tfgweb/metrics.log"
LIKES_FILE="/var/www/tfgweb/metrics_likes.log"

# Borrar los archivos si existen
echo "🧹 Borrando archivos..."
rm -f "$LOG_FILE" "$LIKES_FILE"

# Volver a crearlos vacíos
echo "📁 Creando archivos vacíos..."
touch "$LOG_FILE" "$LIKES_FILE"

# Asignar propietario y grupo a www-data
echo "👤 Asignando propietario y grupo www-data..."
chown www-data:www-data "$LOG_FILE" "$LIKES_FILE"

# Asignar permisos 755
echo "🔒 Asignando permisos 755..."
chmod 755 "$LOG_FILE" "$LIKES_FILE"

echo "✅ Archivos $LOG_FILE y $LIKES_FILE reiniciados correctamente."

