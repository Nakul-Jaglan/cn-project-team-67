# Edge — nginx on Mac 2

| Item | Value |
|---|---|
| Owner | Sudeshhna |
| Listen | `10.3.1.179:8443`, TLS |
| Server names | `app.team67.test`, `api.team67.test` |
| Upstream pool | `10.7.15.25:3001` (A), `10.7.21.130:3002` (B), default round-robin |
| TLS versions | TLS 1.2 and TLS 1.3 |
| Version used | nginx/1.31.6 |

Config: [nginx.conf](nginx.conf). It is the file as deployed, so the certificate paths are absolute paths on Mac 2 (`/Users/sudeshhnabehera/cn-phase1/certs/...`). Change them if running elsewhere.

## Run

```bash
nginx -t -c "$PWD/nginx/nginx.conf"
nginx -c "$PWD/nginx/nginx.conf"
nginx -s reload -c "$PWD/nginx/nginx.conf"     # after edits
nginx -s stop   -c "$PWD/nginx/nginx.conf"
```

Port 8443 is used instead of 443 so nginx does not have to run as root. Logs go to `/tmp/cn-phase1-nginx-access.log` and `/tmp/cn-phase1-nginx-error.log`.

## How it behaves

- **TLS termination.** The client's TLS session ends at nginx. The hop from nginx to a backend is a separate, plain-HTTP TCP connection on the LAN.
- **Round-robin.** With equal weights nginx alternates A, B, A, B.
- **Passive health checks.** `max_fails=1 fail_timeout=5s` takes a backend out of rotation for 5 s after one failed attempt. `proxy_next_upstream error timeout http_502 http_503 http_504` with `proxy_next_upstream_tries 2` retries the request on the other backend, so one backend going down is invisible to the client.
- **Both backends down.** DNS, TCP and TLS still succeed (they terminate at nginx); the HTTP response is `502 Bad Gateway`.
- **Headers.** `Cache-Control`, `ETag` and `X-Backend` from the backend pass through unchanged.

Evidence: [`evidence/04_nginx_tls/`](../evidence/04_nginx_tls).
