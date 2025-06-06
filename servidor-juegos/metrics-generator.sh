#!/bin/bash

# CONFIGURACIÓN
LOG_FILE="/var/www/tfgweb/metrics.log"
LIKES_FILE="/var/www/tfgweb/metrics_likes.log"
INTERVAL_MIN=30
INTERVAL_MAX=45
PROB_FLAPPY=55
PROB_FRUIT=45
MAX_SCORE_FLAPPY=135
MAX_SCORE_FRUIT=226
echo "✅ Iniciando generación por jugador..."

while true; do
  # Seleccionar juego para este jugador
  PROB=$(( RANDOM % 100 ))
  if [ $PROB -lt $PROB_FLAPPY ]; then
    GAME="flappy"
    TIEMPO_BASE=4
  else
    GAME="fruit"
    TIEMPO_BASE=6
  fi

  # Determinar cuántas partidas va a jugar (1-6)
  PARTIDAS=$(( RANDOM % 6 + 1 ))

  for ((i=0; i<PARTIDAS; i++)); do
    # Registrar el start
    START_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")
    echo "$START_TIME - $GAME - start" >> "$LOG_FILE"

    # Determinar la puntuación aleatoria
    if [ "$GAME" == "flappy" ]; then
      SCORE=$(( RANDOM % ($MAX_SCORE_FLAPPY + 1) ))
    else
      SCORE=$(( RANDOM % ($MAX_SCORE_FRUIT + 1) ))
    fi

    # Registrar la puntuación con un pequeño desfase temporal
    SCORE_OFFSET=$(( RANDOM % 10 + 1 ))
    SCORE_TIME=$(date -u -d "$SCORE_OFFSET seconds" +"%Y-%m-%dT%H:%M:%S+00:00")
    echo "$SCORE_TIME - $GAME - score - $SCORE" >> "$LOG_FILE"

    # Registrar like o dislike con otro desfase
    [ $(( RANDOM % 2 )) -eq 0 ] && FEEDBACK="like" || FEEDBACK="dislike"
    FEEDBACK_OFFSET=$(( RANDOM % 15 + 1 ))
    FEEDBACK_TIME=$(date -u -d "$FEEDBACK_OFFSET seconds" +"%Y-%m-%dT%H:%M:%S+00:00")
    echo "$FEEDBACK_TIME - $GAME - $FEEDBACK" >> "$LIKES_FILE"

    # Calcular el tiempo de espera basado en la puntuación
    SCORE=${SCORE:-1}                # Asegurar que SCORE tenga valor
    TIEMPO_BASE=${TIEMPO_BASE:-1}    # Asegurar que TIEMPO_BASE tenga valor
    TIME_WAIT=$(echo "scale=1; ($SCORE/10)*$TIEMPO_BASE" | bc)
    TIME_WAIT=${TIME_WAIT%.*}        # Convertir a entero
    if [ -z "$TIME_WAIT" ] || [ "$TIME_WAIT" -lt 1 ]; then
      TIME_WAIT=1
    fi
    sleep $TIME_WAIT
  done

  # Esperar antes del siguiente jugador
  SLEEP_TIME=$(( RANDOM % ($INTERVAL_MAX - $INTERVAL_MIN + 1) + $INTERVAL_MIN ))
  sleep $SLEEP_TIME
done
