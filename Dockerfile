FROM coturn/coturn:4.10-alpine

# Official image defaults to USER nobody; with a cleared ENTRYPOINT, running as a
# non-root user can cause exec/bind issues on some hosts (e.g. exit 126 on Render).
USER root

COPY turnserver.conf /etc/coturn/turnserver.conf

# Sanity-check binary path (official install prefix is /usr).
RUN test -x /usr/bin/turnserver

# Do not use the stock ENTRYPOINT (docker-entrypoint.sh).
ENTRYPOINT []

# Render sets PORT for HTTP health checks. Use absolute path to coturn binary.
CMD ["/bin/sh", "-c", "set -eu; if [ -n \"${PORT:-}\" ]; then mkdir -p /var/www && printf '%s\\n' 'OK' > /var/www/index.html && busybox httpd -p \"${PORT}\" -h /var/www & fi; EXTRA=\"\"; if [ -n \"${TURN_EXTERNAL_IP:-}\" ]; then EXTRA=\"${EXTRA} --external-ip=${TURN_EXTERNAL_IP}\"; fi; exec /usr/bin/turnserver -c /etc/coturn/turnserver.conf -n --log-file=stdout --simple-log ${EXTRA}"]

EXPOSE 3478/tcp 3478/udp
