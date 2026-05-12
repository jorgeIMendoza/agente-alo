#!/bin/bash

# Procesador de mensajes Telegram para @open_alo_bot
# Escucha /tmp/telegram-pending-message.json y genera respuestas

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Procesador de mensajes iniciado"

LAST_UPDATE_ID=""

while true; do
  PENDING_FILE="/tmp/telegram-pending-message.json"

  if [ -f "$PENDING_FILE" ]; then
    UPDATE_JSON=$(cat "$PENDING_FILE" 2>/dev/null)

    if [ -n "$UPDATE_JSON" ]; then
      UPDATE_ID=$(echo "$UPDATE_JSON" | jq -r '.update_id // empty' 2>/dev/null)
      MESSAGE=$(echo "$UPDATE_JSON" | jq -r '.text // empty' 2>/dev/null)

      # Evitar procesar el mismo mensaje dos veces
      if [ -n "$UPDATE_ID" ] && [ "$UPDATE_ID" != "$LAST_UPDATE_ID" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Procesando mensaje UPDATE_ID: $UPDATE_ID"
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Contenido: $MESSAGE"

        HOUR=$(TZ='America/Mexico_City' date +%H)

        # Pasar al agente Alo para procesamiento real
        PENDING_AGENT="/tmp/alo-pending-telegram.json"
        echo "$UPDATE_JSON" > "$PENDING_AGENT"

        RESPONSE="Procesando tu solicitud... ⚙️"

        # Escribir respuesta
        RESPONSE_FILE="/tmp/telegram-response-$UPDATE_ID.txt"
        echo "$RESPONSE" > "$RESPONSE_FILE"

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Respuesta escrita en $RESPONSE_FILE"

        LAST_UPDATE_ID=$UPDATE_ID

        # Limpiar el archivo de entrada después de procesar
        rm -f "$PENDING_FILE"
      fi
    fi
  fi

  sleep 0.5
done
