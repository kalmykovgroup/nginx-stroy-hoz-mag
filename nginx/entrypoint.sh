#!/bin/sh

: "${DOMAIN:?❌ DOMAIN не задан! Проверь переменные окружения.}" 
: "${IP_VM_1C:?❌ IP_VM_1C не задан! Проверь переменные окружения.}" 
: "${IP_VM_STORE:?❌ IP_VM_STORE не задан! Проверь переменные окружения.}" 
: "${PROXMOX_IP:?❌ PROXMOX_IP не задан! Проверь переменные окружения.}" 
: "${PROXMOX_PORT:?❌ PROXMOX_PORT не задан! Проверь переменные окружения.}" 
: "${DOMAIN_1C:?❌ DOMAIN_1C не задан! Проверь переменные окружения.}" 
: "${IP_VM_CLIENT_1C:?❌ IP_VM_CLIENT_1C не задан! Проверь переменные окружения.}" 
: "${WILDCARD_DOMAIN_1C:?❌ WILDCARD_DOMAIN_1C не задан! Проверь переменные окружения.}" 
: "${DOMAIN_VM_CLIENT_1C:?❌ DOMAIN_VM_CLIENT_1C не задан! Проверь переменные окружения.}" 
 
echo "🧹 Очищаем логи..."
find "/var/log/nginx/" -type f -name "*.log" -exec truncate -s 0 {} \;


echo "📁 Список /etc/nginx/conf.d до генерации:"
ls -l /etc/nginx/conf.d 

export DOMAIN_1C
export DOMAIN
export IP_VM_1C
export IP_VM_STORE
export PROXMOX_IP
export PROXMOX_PORT
export DOMAIN_VM_CLIENT_1C
export IP_VM_CLIENT_1C
export WILDCARD_DOMAIN_1C

CERT_PATH="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"

CONF_DIR="/etc/nginx/conf.d"
STREAM_DIR="/etc/nginx/stream.d"

TEMPLATES="/etc/nginx/templates"

TEMPLATE_HTTP="$TEMPLATES/default.http.template"
TEMPLATE_HTTPS="$TEMPLATES/http.template"
TEMPLATE_STREAM="$TEMPLATES/stream.template"

TARGET_CONF="$CONF_DIR/default.conf"
TARGET_STREAM_CONF="$STREAM_DIR/stream.conf"

echo "DOMAIN: $DOMAIN"
echo "IP_VM_1C: $IP_VM_1C"
echo "IP_VM_STORE:  $IP_VM_STORE"
echo "PROXMOX_IP:  $PROXMOX_IP"
echo "PROXMOX_PORT:  $PROXMOX_PORT"
echo "DOMAIN_1C:  $DOMAIN_1C"
echo "IP_VM_CLIENT_1C:  $IP_VM_CLIENT_1C"
echo "DOMAIN_VM_CLIENT_1C:  $DOMAIN_VM_CLIENT_1C"
echo "WILDCARD_DOMAIN_1C:  $WILDCARD_DOMAIN_1C"

echo "🌐 NGINX entrypoint запущен..."

if [ -f "$CERT_PATH" ]; then

  echo "🔒 SSL-сертификат найден, генерируем конфиг с HTTPS..."
  envsubst '${DOMAIN} ${DOMAIN_1C} ${IP_VM_STORE} ${IP_VM_1C} ${PROXMOX_IP} ${PROXMOX_PORT} ${IP_VM_CLIENT_1C} ${DOMAIN_VM_CLIENT_1C} ${WILDCARD_DOMAIN_1C}' < "$TEMPLATE_HTTPS" > "$TARGET_CONF"
  envsubst '${IP_VM_CLIENT_1C}' < "$TEMPLATE_STREAM" > "$TARGET_STREAM_CONF"
else
  echo "🌐 SSL ещё нет, запускаемся с HTTP-only..."
  envsubst '${DOMAIN} ${DOMAIN_1C}' < "$TEMPLATE_HTTP" > "$TARGET_CONF"
fi

echo "📁 Список /etc/nginx/conf.d после генерации:"
ls -l /etc/nginx/conf.d
echo "📄 Содержимое default.conf:"
cat /etc/nginx/conf.d/default.conf 

echo "📁 Список /etc/nginx/stream.d после генерации:"
ls -l /etc/nginx/stream.d
echo "📄 Содержимое stream.conf:"
cat /etc/nginx/stream.d/stream.conf 

echo "🚀 Запуск nginx..."
nginx -g "daemon off;"
