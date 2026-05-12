#!/bin/bash

# Agente Alo para procesar mensajes Telegram con Claude API

source /home/srvsozu/.openclaw/secrets/.bw-credentials
export BW_CLIENTID
export BW_CLIENTSECRET

BW_SESSION_FILE="/tmp/.bw-session-alo"

get_anthropic_key() {
  if [ -f "$BW_SESSION_FILE" ]; then
    export BW_SESSION=$(cat "$BW_SESSION_FILE")
    KEY=$(bw get item "api-openclaw" 2>/dev/null | jq -r '.fields[0].value // empty')
    if [ -n "$KEY" ]; then
      echo "$KEY"
      return 0
    fi
  fi

  BW_SESSION=$(bw unlock "$BW_MASTER_PASSWORD" --raw 2>/dev/null)
  if [ -z "$BW_SESSION" ]; then
    return 1
  fi

  export BW_SESSION
  echo "$BW_SESSION" > "$BW_SESSION_FILE"
  chmod 600 "$BW_SESSION_FILE"

  KEY=$(bw get item "api-openclaw" 2>/dev/null | jq -r '.fields[0].value // empty')
  if [ -n "$KEY" ]; then
    echo "$KEY"
    return 0
  fi

  return 1
}

ANTHROPIC_KEY=$(get_anthropic_key)
if [ -z "$ANTHROPIC_KEY" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: No se pudo obtener API key de Anthropic"
  exit 1
fi

export ANTHROPIC_API_KEY="$ANTHROPIC_KEY"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Agente Alo iniciado"

while true; do
  PENDING_FILE="/tmp/telegram-pending-message.json"

  if [ -f "$PENDING_FILE" ]; then
    UPDATE_JSON=$(cat "$PENDING_FILE" 2>/dev/null)

    if [ -n "$UPDATE_JSON" ]; then
      UPDATE_ID=$(echo "$UPDATE_JSON" | jq -r '.update_id // empty' 2>/dev/null)
      MESSAGE=$(echo "$UPDATE_JSON" | jq -r '.text // empty' 2>/dev/null)
      USERNAME=$(echo "$UPDATE_JSON" | jq -r '.username // "Usuario"' 2>/dev/null)

      if [ -n "$UPDATE_ID" ] && [ -n "$MESSAGE" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] Procesando mensaje de @$USERNAME: $MESSAGE"

        RESPONSE=$(curl -s https://api.anthropic.com/v1/messages \
          -H "Content-Type: application/json" \
          -H "x-api-key: $ANTHROPIC_KEY" \
          -H "anthropic-version: 2023-06-01" \
          -d "{
            \"model\": \"claude-opus-4-7\",
            \"max_tokens\": 1024,
            \"system\": \"Eres Alo, agente de infraestructura de Sozu. Responde de forma directa y concisa. El usuario es Jorge Mendoza (su alteza). Habla en español siempre.\",
            \"messages\": [
              {
                \"role\": \"user\",
                \"content\": \"$MESSAGE\"
              }
            ]
          }" | jq -r '.content[0].text // empty')

        if [ -n "$RESPONSE" ]; then
          RESPONSE_FILE="/tmp/telegram-response-$UPDATE_ID.txt"
          echo "$RESPONSE" > "$RESPONSE_FILE"
          echo "[$(date '+%Y-%m-%d %H:%M:%S')] Respuesta generada: $RESPONSE_FILE"
        else
          echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: No se generó respuesta para UPDATE_ID $UPDATE_ID"
        fi

        rm -f "$PENDING_FILE"
      fi
    fi
  fi

  sleep 0.5
done
