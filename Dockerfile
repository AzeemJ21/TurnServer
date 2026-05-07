FROM coturn/coturn:4.10-alpine

COPY turnserver.conf /etc/coturn/turnserver.conf

# Do not use the stock image entrypoint; run coturn explicitly with our config.
ENTRYPOINT []

# Render injects PORT for HTTP health checks; coturn reads credentials from turnserver.conf only.
# Optional TURN_EXTERNAL_IP maps to --external-ip (recommended on cloud hosts).
CMD ["sh", "-c", "set -eu; if [ -n \"${PORT:-}\" ]; then mkdir -p /var/www && printf '%s\\n' 'OK' > /var/www/index.html && busybox httpd -p \"${PORT}\" -h /var/www & fi; EXTRA=\"\"; if [ -n \"${TURN_EXTERNAL_IP:-}\" ]; then EXTRA=\"${EXTRA} --external-ip=${TURN_EXTERNAL_IP}\"; fi; exec turnserver -c /etc/coturn/turnserver.conf -n --log-file=stdout --simple-log ${EXTRA}"]

EXPOSE 3478/tcp 3478/udp
