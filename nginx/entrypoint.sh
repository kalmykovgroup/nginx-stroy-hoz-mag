#!/bin/sh
 
: "${PROXMOX_IP:?❌ PROXMOX_IP не задан! Проверь переменные окружения.}" 
: "${PROXMOX_PORT:?❌ PROXMOX_PORT не задан! Проверь переменные окружения.}"  

: "${IP_VM_CLIENT_1C:?❌ IP_VM_CLIENT_1C не задан! Проверь переменные окружения.}" 
: "${DOMAIN:?❌ DOMAIN не задан! Проверь переменные окружения.}"  
 
echo "🧹 Очищаем логи..."
find "/var/log/nginx/" -type f -name "*.log" -exec truncate -s 0 {} \;


echo "📁 Список /etc/nginx/conf.d до генерации:"
ls -l /etc/nginx/conf.d 
 
export PROXMOX_IP
export PROXMOX_PORT

export DOMAIN
export IP_VM_CLIENT_1C
 

CERT_PATH="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"

CONF_DIR="/etc/nginx/conf.d"
STREAM_DIR="/etc/nginx/stream.d"

TEMPLATES="/etc/nginx/templates"

TEMPLATE_HTTP="$TEMPLATES/default.http.template"
TEMPLATE_HTTPS="$TEMPLATES/http.template"
TEMPLATE_STREAM="$TEMPLATES/stream.template"

TARGET_CONF="$CONF_DIR/default.conf"
TARGET_STREAM_CONF="$STREAM_DIR/stream.conf"
 
echo "PROXMOX_IP:  $PROXMOX_IP"
echo "PROXMOX_PORT:  $PROXMOX_PORT" 

echo "IP_VM_CLIENT_1C:  $IP_VM_CLIENT_1C"
echo "DOMAIN:  $DOMAIN" 

echo "🌐 NGINX entrypoint запущен..."

if [ -f "$CERT_PATH" ]; then

  echo "🔒 SSL-сертификат найден, генерируем конфиг с HTTPS..."
  envsubst '${PROXMOX_IP} ${PROXMOX_PORT} ${IP_VM_CLIENT_1C} ${DOMAIN}' < "$TEMPLATE_HTTPS" > "$TARGET_CONF"
  envsubst '${DOMAIN}' < "$TEMPLATE_STREAM" > "$TARGET_STREAM_CONF"
else
  echo "🌐 SSL ещё нет, запускаемся с HTTP-only..."
  envsubst '${DOMAIN}' < "$TEMPLATE_HTTP" > "$TARGET_CONF"
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
