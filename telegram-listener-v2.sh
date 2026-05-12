#!/bin/bash

# Telegram @open_alo_bot Listener v2
# Delega procesamiento a OpenClaw (Alo Agent)

source /home/srvsozu/.openclaw/secrets/.bw-credentials
export BW_CLIENTID
export BW_CLIENTSECRET

BW_SESSION_FILE="/tmp/.bw-session-alo"

# Función para obtener token con reintentos
get_token() {
  if [ -f "$BW_SESSION_FILE" ]; then
    export BW_SESSION=$(cat "$BW_SESSION_FILE")
    TOKEN=$(bw get item "Token @open_alo_bot" 2>/dev/null | jq -r '.notes // empty')
    if [ -n "$TOKEN" ]; then
      echo "$TOKEN"
      return 0
    fi
  fi

  # Si no tenemos sesión válida, desbloqueamos
  BW_SESSION=$(bw unlock "$BW_MASTER_PASSWORD" --raw 2>/dev/null)
  if [ -z "$BW_SESSION" ]; then
    return 1
  fi

  export BW_SESSION
  echo "$BW_SESSION" > "$BW_SESSION_FILE"
  chmod 600 "$BW_SESSION_FILE"

  TOKEN=$(bw get item "Token @open_alo_bot" 2>/dev/null | jq -r '.notes // empty')
  if [ -n "$TOKEN" ]; then
    echo "$TOKEN"
    return 0
  fi

  return 1
}

TOKEN=$(get_token)
if [ -z "$TOKEN" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: No se pudo obtener el token de Bitwarden"
  exit 1
fi

OFFSET=0
STATE_FILE="/tmp/telegram-listener-state.json"

if [ -f "$STATE_FILE" ]; then
  OFFSET=$(jq -r '.last_offset // 0' "$STATE_FILE" 2>/dev/null)
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Listener iniciado"

while true; do
  UPDATES=$(curl -s "https://api.telegram.org/bot${TOKEN}/getUpdates?offset=$((OFFSET+1))&timeout=30&allowed_updates=message")

  RESULT=$(echo "$UPDATES" | jq -r '.result[] | @json' 2>/dev/null)

  while IFS= read -r UPDATE_JSON; do
    [ -z "$UPDATE_JSON" ] && continue

    UPDATE_ID=$(echo "$UPDATE_JSON" | jq -r '.update_id')
    MESSAGE=$(echo "$UPDATE_JSON" | jq -r '.message.text // empty')
    CHAT_ID=$(echo "$UPDATE_JSON" | jq -r '.message.chat.id // empty')
    MESSAGE_ID=$(echo "$UPDATE_JSON" | jq -r '.message.message_id // 0')
    USERNAME=$(echo "$UPDATE_JSON" | jq -r '.message.from.username // "Usuario"')

    if [ -z "$CHAT_ID" ]; then
      continue
    fi

    # Detectar si el mensaje menciona al bot (en 1-a-1 o en grupo)
    # En chats privados (chat_id < 0 o es grupo), responder a cualquier mensaje que mencione al bot
    BOT_MENTIONED=$(echo "$UPDATE_JSON" | jq -r '.message.entities[]? | select(.type=="mention" or .type=="text_mention") | .user.username // ""' 2>/dev/null | grep -i "open_alo_bot")
    MESSAGE_HAS_ALO=$(echo "$MESSAGE" | grep -qi "@open_alo_bot\|alo" && echo "1" || echo "0")
    CHAT_TYPE=$(echo "$UPDATE_JSON" | jq -r '.message.chat.type // "private"')

    # Procesar si: es grupo Y menciona bot, O es privado Y no está vacío
    if { [ "$CHAT_TYPE" = "group" ] || [ "$CHAT_TYPE" = "supergroup" ]; } && [ -n "$BOT_MENTIONED" ]; then
      SHOULD_PROCESS=1
    elif { [ "$CHAT_TYPE" = "private" ]; } && [ -n "$MESSAGE" ]; then
      SHOULD_PROCESS=1
    elif [ -n "$MESSAGE" ] && [ "$MESSAGE_HAS_ALO" = "1" ]; then
      SHOULD_PROCESS=1
    else
      SHOULD_PROCESS=0
    fi

    if [ "$SHOULD_PROCESS" = "1" ]; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] Procesando mensaje de @$USERNAME en chat $CHAT_ID (tipo: $CHAT_TYPE)"

      # Guardar update para procesamiento
      echo "{\"update_id\": $UPDATE_ID, \"chat_id\": $CHAT_ID, \"message_id\": $MESSAGE_ID, \"username\": \"$USERNAME\", \"text\": \"$MESSAGE\", \"timestamp\": \"$(date -Iseconds)\"}" > /tmp/telegram-pending-message.json

      # Esperar a que se procese (máx 10 segundos)
      RESPONSE_FILE="/tmp/telegram-response-$UPDATE_ID.txt"
      WAITED=0
      while [ ! -f "$RESPONSE_FILE" ] && [ $WAITED -lt 450 ]; do
        sleep 0.2
        WAITED=$((WAITED + 1))
      done

      if [ -f "$RESPONSE_FILE" ]; then
        RESPONSE=$(cat "$RESPONSE_FILE")
        rm -f "$RESPONSE_FILE"

        ESCAPED_RESPONSE=$(echo "$RESPONSE" | sed 's/"/\\"/g')

        curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
          -H "Content-Type: application/json" \
          -d "{\"chat_id\": $CHAT_ID, \"text\": \"$ESCAPED_RESPONSE\", \"reply_to_message_id\": $MESSAGE_ID}" \
          > /dev/null

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Respuesta enviada a chat $CHAT_ID"
      else
        # Fallback si no hay respuesta
        RESPONSE="Procesando tu solicitud...creo que algo anda mal!!!"
        ESCAPED_RESPONSE=$(echo "$RESPONSE" | sed 's/"/\\"/g')

        curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
          -H "Content-Type: application/json" \
          -d "{\"chat_id\": $CHAT_ID, \"text\": \"$ESCAPED_RESPONSE\", \"reply_to_message_id\": $MESSAGE_ID}" \
          > /dev/null

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Fallback response en chat $CHAT_ID"
      fi

      echo "{\"last_offset\": $UPDATE_ID, \"last_update\": \"$(date -Iseconds)\"}" > "$STATE_FILE"
      OFFSET=$UPDATE_ID
    fi
  done <<< "$RESULT"

  sleep 1
done
