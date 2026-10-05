# IP and service table

Values in use during the evidence session (5–6 October 2026 IST). Addresses are DHCP-assigned; re-check with `ipconfig getifaddr en0` at the start of every session and update `dns/dnsmasq.conf` and `nginx/nginx.conf` if they change.

## Machines

| Machine | Owner | Role | IP address | Interface |
|---|---|---|---|---|
| Mac 1 | Nakul | Private DNS + client | `10.7.17.54` | `en0` |
| Mac 2 | Sudeshhna | nginx edge: TLS, reverse proxy, load balancer | `10.3.1.179` | — |
| Mac 3 | Neelanshu | Backend A | `10.7.15.25` | — |
| Mac 4 | Puneet | Backend B + test client + packet capture | `10.7.21.130` | `en0` |

Subnet mask, gateway and MAC addresses: to be filled from the LAN inventory (`evidence/01_lan/`).

## Services

| Service | Machine | Address : port | Transport | Application protocol |
|---|---|---|---|---|
| Private DNS | Mac 1 | `10.7.17.54:53` | UDP (TCP fallback) | DNS |
| HTTPS edge | Mac 2 | `10.3.1.179:8443` | TCP | HTTP/1.1 over TLS 1.2 / 1.3 |
| Backend A | Mac 3 | `10.7.15.25:3001` | TCP | HTTP (plain) |
| Backend B | Mac 4 | `10.7.21.130:3002` | TCP | HTTP (plain) |

## Names

| Name | Type | Value | Served by |
|---|---|---|---|
| `app.team67.test` | A | `10.3.1.179` | dnsmasq on Mac 1 |
| `api.team67.test` | A | `10.3.1.179` | dnsmasq on Mac 1 |

Final URL: `https://app.team67.test:8443/`

## Endpoints (both backends)

| Path | Result |
|---|---|
| `/` | 200 JSON |
| `/api/status` | 200 JSON |
| other | 404 |
