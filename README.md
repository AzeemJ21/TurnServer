# TURN server (coturn + Docker)

Production-oriented [coturn](https://github.com/coturn/coturn) on the official [`coturn/coturn`](https://hub.docker.com/r/coturn/coturn) image. Credentials and realm live in `turnserver.conf` (long-term credentials / `lt-cred-mech`). The container starts **`turnserver`** explicitly with **`-c /etc/coturn/turnserver.conf`** (see `Dockerfile`).

## Built-in credentials (must match your WebRTC client)

| Field | Value |
|-------|--------|
| Realm | `chatroom.app` |
| Username | `chatuser` |
| Password | `supersecurepass123` |

**Security:** These values are in the repository by design for this template. For a real deployment, change them in `turnserver.conf`, rebuild the image, and update your app env vars.

## Environment variables

| Variable | Required | Description |
|----------|----------|-------------|
| `PORT` | On Render | Render sets this automatically. A tiny BusyBox `httpd` binds it so **HTTP health checks** succeed; coturn still uses **3478** for TURN. |
| `TURN_EXTERNAL_IP` | Strongly recommended | Your service’s **public IPv4** passed to coturn as **`--external-ip`**. Without it, relay candidates can be wrong behind NAT/cloud. Find Render instance outbound IP or use your stable hostname’s resolved A record if applicable. |

No variables are required for username/password; those come from `turnserver.conf`.

## Deploy on [Render](https://render.com)

1. Connect this GitHub repo and create a **Web Service** with **Docker**.
2. Use the root **`Dockerfile`** (default).
3. Under **Environment**, set **`TURN_EXTERNAL_IP`** to your instance’s public IPv4 (see Render docs / dashboard for outbound IP if needed).
4. Open firewall / port mapping for **3478 TCP and UDP**, and **UDP 49152–65535** for relay traffic (match `min-port` / `max-port` in `turnserver.conf`). If your platform cannot expose a huge UDP range, lower `max-port` in `turnserver.conf` and expose **that** range consistently everywhere.
5. Deploy and check **Logs**: you should see coturn startup lines (no interactive CLI; `no-cli` is set in config).

## Local run

```bash
docker build -t turn-server .

docker run --rm \
  -e TURN_EXTERNAL_IP=203.0.113.10 \
  -p 3478:3478/tcp -p 3478:3478/udp \
  -p 49152-65535:49152-65535/udp \
  turn-server
```

Replace `TURN_EXTERNAL_IP` with this machine’s public IP when testing from the internet.

## WebRTC / ICE (`iceServers`)

Align env vars with your Render hostname:

```text
TURN_SERVER_URL=turn:your-render-url.onrender.com:3478
TURN_USERNAME=chatuser
TURN_CREDENTIAL=supersecurepass123
```

Example `RTCPeerConnection` configuration:

```javascript
const iceServers = [
  {
    urls: [
      'turn:your-render-url.onrender.com:3478?transport=udp',
      'turn:your-render-url.onrender.com:3478?transport=tcp',
    ],
    username: 'chatuser',
    credential: 'supersecurepass123',
  },
];

const pc = new RTCPeerConnection({ iceServers });
```

Use your real Render host instead of `your-render-url.onrender.com`.

## Troubleshooting (common TURN failures)

| Symptom | Likely cause | What to try |
|--------|----------------|-------------|
| ICE stays on `relay` failed or never connects | Wrong advertised address | Set **`TURN_EXTERNAL_IP`** to the correct **public** IPv4 used by clients to reach this host. |
| Authentication errors (`401`, `nonce`, credential rejected) | Client/server mismatch | Client **`username` / `credential`** must match **`user=`** and **`realm=`** in `turnserver.conf`. |
| UDP relay fails but TCP might work | Firewall / UDP range blocked | Open **UDP 3478** and **UDP 49152–65535** (or your configured relay range) on the host and any cloud security rules. |
| Works on LAN, fails from internet | NAT / hairpin | Test from an external network; confirm **`TURN_EXTERNAL_IP`** is the WAN address, not a private IP. |
| Render health check fails | Nothing on **`PORT`** | Ensure you deploy as a **Web Service** so Render injects **`PORT`**; the image serves `OK` on that port only for health checks. |
| Logs show CLI or hang | Rare image override | This Dockerfile clears **`ENTRYPOINT`** and runs **`turnserver -c ...`** only; rebuild without caching if needed. |

## References

- [coturn Docker README](https://github.com/coturn/coturn/blob/master/docker/coturn/README.md)
- [RFC 5766 — TURN](https://datatracker.ietf.org/doc/html/rfc5766)
