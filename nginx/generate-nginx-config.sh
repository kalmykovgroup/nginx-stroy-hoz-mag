#!/bin/bash

CLIENT_ID=$1
VM_IP=$2
DOMAIN="${CLIENT_ID}.1c.kalmykov-group.com"
STREAM_PORT_START=1560
STREAM_PORT_END=1564

CONF_DIR="./nginx/conf.d"
STREAM_DIR="./nginx/stream.d"
TEMPLATE_DIR="./nginx/templates"

# Генерация dynamic stream-блоков
DYNAMIC_BLOCK=""
for PORT in $(seq $STREAM_PORT_START $STREAM_PORT_END); do
DYNAMIC_BLOCK+="
server {
    listen ${PORT};
    proxy_pass ${VM_IP}:${PORT};
}
"
done

# Генерация stream конфигурации
sed \
  -e "s|{{VM_IP}}|${VM_IP}|g" \
  -e "s|{{DYNAMIC_STREAM_BLOCK}}|${DYNAMIC_BLOCK}|" \
  ${TEMPLATE_DIR}/stream.template > "${STREAM_DIR}/${CLIENT_ID}.stream"

# Генерация http(s) конфигурации
sed \
  -e "s|{{DOMAIN}}|${DOMAIN}|g" \
  -e "s|{{VM_IP}}|${VM_IP}|g" \
  ${TEMPLATE_DIR}/http.template > "${CONF_DIR}/${CLIENT_ID}.conf"

echo "✅ Конфигурации созданы для клиента ${CLIENT_ID}"

docker compose exec nginx nginx -s reload
echo "🔁 Nginx перезапущен"
