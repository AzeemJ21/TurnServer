FROM coturn/coturn:4.10-alpine

COPY turnserver.conf /etc/coturn/turnserver.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN chmod +x /docker-entrypoint.sh

EXPOSE 3478/tcp 3478/udp 5349/tcp 5349/udp

ENTRYPOINT ["/docker-entrypoint.sh"]
