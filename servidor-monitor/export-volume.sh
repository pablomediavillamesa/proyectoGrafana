#!/bin/bash

# Variables de los volúmenes y archivos de backup
VOLUMENES=("servidor-monitor_alertmanager_data" "servidor-monitor_grafana_data")
ARCHIVOS=("backup_alertmanager_data.tar.gz" "backup_grafana_data.tar.gz")

for i in ${!VOLUMENES[@]}; do
  VOLUMEN=${VOLUMENES[$i]}
  ARCHIVO=${ARCHIVOS[$i]}
  echo "Exportando volumen $VOLUMEN a $ARCHIVO ..."
  docker run --rm \
    -v ${VOLUMEN}:/data \
    -v $(pwd):/backup \
    busybox \
    tar czf /backup/${ARCHIVO} -C /data .
  echo "Volumen $VOLUMEN exportado como $ARCHIVO"
done

