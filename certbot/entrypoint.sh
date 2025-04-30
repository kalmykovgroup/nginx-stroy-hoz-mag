#!/usr/bin/env bash
set -euo pipefail

: "${DOMAIN:?❌ DOMAIN не задан!}" 
: "${DOMAIN_1C:?❌ DOMAIN_1C не задан!}" 
: "${WILDCARD_DOMAIN_1C:?❌ WILDCARD_DOMAIN_1C не задан!}" 
: "${CERTBOT_EMAIL:?❌ CERTBOT_EMAIL не задан!}" 

echo "🌐 Certbot entrypoint запущен..."
echo "🔹 DOMAIN: ${DOMAIN}"
echo "🔹 DOMAIN_1C: ${DOMAIN_1C}"
echo "🔹 EMAIL: ${CERTBOT_EMAIL}"
echo "🔹 WILDCARD_DOMAIN_1C: ${WILDCARD_DOMAIN_1C}"

CLOUDFLARE_CRED="/cloudflare.ini"
RENEW_CRON="/etc/cron.d/certbot-renew"

issue_if_missing() {
  local cert_name="$1"
  local domains=("${@:2}")
  local cert_path="/etc/letsencrypt/live/${cert_name}/fullchain.pem"

  if [[ -f "$cert_path" ]]; then
    echo "✅ Сертификат для ${cert_name} уже существует — пропускаем"
    return
  fi

  echo "🔐 Выпуск сертификата для ${cert_name}:"
  for d in "${domains[@]}"; do echo "   - $d"; done

  set +e  # временно отключаем остановку по ошибке
  output=$(certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials "$CLOUDFLARE_CRED" \
    --dns-cloudflare-propagation-seconds 30 \
    --cert-name "$cert_name" \
    "${domains[@]/#/-d }" \
    --agree-tos \
    --email "$CERTBOT_EMAIL" \
    --non-interactive 2>&1)
  status=$?
  set -e

  if [[ $status -ne 0 ]]; then
    if echo "$output" | grep -q "too many certificates"; then
      echo "⛔ Превышен лимит Let's Encrypt на выпуск для ${cert_name}"
      echo "$output" | grep -oE "retry after .*" || true
    else
      echo "❌ Ошибка при выпуске сертификата для ${cert_name}:"
      echo "$output"
    fi
  else
    echo "✅ Сертификат успешно выпущен для ${cert_name}"
  fi
}


# --- Выпуск всех нужных сертификатов ---
issue_if_missing "${DOMAIN}" "${DOMAIN}"                        # kalmykov.group
issue_if_missing "${DOMAIN_1C}" "${DOMAIN_1C}"          # 1c.kalmykov.group
issue_if_missing "${WILDCARD_DOMAIN_1C}" "*.${DOMAIN_1C}"        # *.1c.kalmykov.group — wildcard


# --- Cron для продления ---
echo "0 3 * * * root certbot renew \
      --quiet \
      --dns-cloudflare \
      --dns-cloudflare-credentials $CLOUDFLARE_CRED \
      --post-hook 'docker exec nginx nginx -s reload'" > "$RENEW_CRON"
chmod 0644 "$RENEW_CRON"
echo "🗓  Cron‑задача для продления создана: $RENEW_CRON"

echo "🚀 Запуск cron (foreground)..."
cron -f
