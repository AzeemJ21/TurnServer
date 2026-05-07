#!/bin/sh
set -eu

if [ -z "${TURN_USER:-}" ] || [ -z "${TURN_PASSWORD:-}" ]; then
  echo "coturn: TURN_USER and TURN_PASSWORD must be set" >&2
  exit 1
fi

REALM="${TURN_REALM:-turn.local}"

# Render Web Services perform HTTP health checks on PORT; coturn listens on TURN ports separately.
if [ -n "${PORT:-}" ]; then
  mkdir -p /var/www
  printf '%s\n' 'OK' > /var/www/index.html
  busybox httpd -p "$PORT" -h /var/www &
fi

set -- turnserver \
  -c /etc/coturn/turnserver.conf \
  -n \
  --log-file=stdout \
  --simple-log \
  --realm="$REALM" \
  --user="${TURN_USER}:${TURN_PASSWORD}"

if [ -n "${TURN_TLS_CERT:-}" ] && [ -n "${TURN_TLS_KEY:-}" ] \
  && [ -f "$TURN_TLS_CERT" ] && [ -f "$TURN_TLS_KEY" ]; then
  set -- "$@" --tls-listening-port=5349 --cert="$TURN_TLS_CERT" --pkey="$TURN_TLS_KEY"
fi

if [ -n "${TURN_EXTERNAL_IP:-}" ]; then
  set -- "$@" --external-ip="$TURN_EXTERNAL_IP"
elif [ "${DETECT_EXTERNAL_IP:-}" = "yes" ] && command -v detect-external-ip >/dev/null 2>&1; then
  DETECTED="$(detect-external-ip)"
  if [ -n "$DETECTED" ]; then
    set -- "$@" --external-ip="$DETECTED"
  fi
fi

if [ -n "${TURN_RELAY_IP:-}" ]; then
  set -- "$@" --relay-ip="$TURN_RELAY_IP"
fi

exec "$@"
