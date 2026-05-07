# TURN server (coturn + Docker)

Minimal production-oriented [coturn](https://github.com/coturn/coturn) deployment using the official [`coturn/coturn`](https://hub.docker.com/r/coturn/coturn) image. Intended for WebRTC relay traffic behind restrictive NATs.

## Quick run (local)

```bash
docker build -t turn-server .

docker run --rm \
  -e TURN_USER=myuser \
  -e TURN_PASSWORD='your-strong-secret' \
  -e TURN_REALM=example.com \
  -e TURN_EXTERNAL_IP=203.0.113.10 \
  -p 3478:3478/tcp -p 3478:3478/udp \
  -p 5349:5349/tcp -p 5349:5349/udp \
  -p 49152-65535:49152-65535/udp \
  turn-server
```

Replace `TURN_EXTERNAL_IP` with your machine’s public IPv4 (required when clients cannot discover the correct relay address themselves).

### TLS (optional, port 5349)

Mount PEM files and point the container at them:

```bash
docker run --rm \
  -e TURN_USER=myuser \
  -e TURN_PASSWORD='your-strong-secret' \
  -e TURN_REALM=example.com \
  -e TURN_TLS_CERT=/certs/fullchain.pem \
  -e TURN_TLS_KEY=/certs/privkey.pem \
  -v /path/to/certs:/certs:ro \
  -p 3478:3478/tcp -p 3478:3478/udp \
  -p 5349:5349/tcp -p 5349:5349/udp \
  -p 49152-65535:49152-65535/udp \
  turn-server
```

If `TURN_TLS_CERT` / `TURN_TLS_KEY` are unset or files are missing, the server listens on **3478 only** (UDP/TCP).

## Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `TURN_USER` | Yes | Long-term credential username |
| `TURN_PASSWORD` | Yes | Long-term credential password (avoid `:` in the password) |
| `TURN_REALM` | No | Realm string (default `turn.local`; set to your domain for production) |
| `TURN_EXTERNAL_IP` | Recommended | Public IPv4 for `--external-ip` (typical on cloud VMs) |
| `TURN_RELAY_IP` | No | Optional `--relay-ip` if it must differ from the external IP |
| `TURN_TLS_CERT` | No | Path inside the container to the TLS certificate PEM |
| `TURN_TLS_KEY` | No | Path inside the container to the TLS private key PEM |
| `DETECT_EXTERNAL_IP` | No | Set to `yes` to call `detect-external-ip` when present (ignored if `TURN_EXTERNAL_IP` is set) |
| `PORT` | On Render | Render injects this; a tiny HTTP health server binds it (see below) |

Logs go to **stdout** (`--log-file=stdout`), suitable for platforms that aggregate container logs.

## Deploy on [Render](https://render.com) (Docker Web Service)

1. Push this repository to GitHub and create a **Web Service** → **Docker**.
2. Set **Dockerfile path** to `Dockerfile` (root of the repo).
3. Add environment variables in the Render dashboard (minimum `TURN_USER`, `TURN_PASSWORD`, `TURN_REALM`, and `TURN_EXTERNAL_IP` with your instance’s **egress/public IP**).
4. **Open ports**: Map **3478** TCP/UDP and (if you use TLS) **5349** TCP/UDP. Map a **UDP range** for relay ports consistent with `min-port` / `max-port` in `turnserver.conf` (default `49152–65535`), or reduce the range in config and expose only that range.
5. Render Web Services expect something to listen on the **`PORT`** environment variable for HTTP health checks. This image starts a minimal **BusyBox `httpd`** on `PORT` that serves `OK`, while coturn continues to listen on **3478** (and **5349** when TLS files are provided).

**Note:** UDP-heavy workloads depend on your Render plan and networking; verify relay connectivity from real clients. If full UDP port ranges are impractical, lower `max-port` in `turnserver.conf` and expose that narrower UDP range in Render/YAML/firewall consistently.

## WebRTC `iceServers` example

Use the same username/password you configured (long-term credentials):

```javascript
const iceServers = [
  {
    urls: [
      'turn:turn.example.com:3478?transport=udp',
      'turn:turn.example.com:3478?transport=tcp',
    ],
    username: 'myuser',
    credential: 'your-strong-secret',
  },
];

// If TLS is enabled on 5349 (turns:):
// urls: ['turns:turn.example.com:5349?transport=tcp', ...]
```

Replace `turn.example.com` with your DNS name or host. Prefer **TLS** (`turns:`) when certificates are configured.

## References

- [coturn Docker Hub README](https://github.com/coturn/coturn/blob/master/docker/coturn/README.md)
- [RFC 5766 — TURN](https://datatracker.ietf.org/doc/html/rfc5766)
