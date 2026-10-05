# Phase 1 evidence checklist

Every Phase 1 requirement, the command that verifies it, the observed result, and the file that holds the proof. Session: 5–6 October 2026 (IST). Status values: **Verified** (evidence saved in this repository) or **Pending** (evidence not yet collected).

## A. LAN and private DNS

| ID | Requirement | Command | Observed | Evidence | Status |
|---|---|---|---|---|---|
| A1 | All machines reachable pairwise | `ping -c 3 <each IP>` from every Mac | — | `evidence/01_lan/` | Pending |
| A2 | `app.team67.test` resolves to the edge via Mac 1 | `dig app.team67.test` | `NOERROR`, `flags: qr aa rd ra`, answer `10.3.1.179`, `SERVER: 10.7.17.54#53` | `evidence/02_dns/dig-client-to-mac1.txt` | Verified |
| A3 | `api.team67.test` resolves to the edge | `dig api.team67.test` | answer `10.3.1.179` from `10.7.17.54#53` | same file | Verified |
| A4 | Client uses the team DNS as system resolver | `networksetup -getdnsservers "Wi-Fi"` | `10.7.17.54` | same file | Verified |

## B. Backends

| ID | Requirement | Command | Observed | Evidence | Status |
|---|---|---|---|---|---|
| B1 | Backend B answers locally on `/`, `/api/status`; 404 elsewhere | `curl -sS -D - http://127.0.0.1:3002/...` | 200, 200, 404; `X-Backend: B` | `evidence/03_backends/backend-B-local-and-remote.txt` | Verified |
| B2 | Backend B reachable from other Macs | `curl -sS -D - http://10.7.21.130:3002/api/status; nc -vz 10.7.21.130 3002` | 200 + port open, from two other Macs including the edge | same file | Verified |
| B3 | Backend A answers locally and remotely | same commands against `10.7.15.25:3001` | — | `evidence/03_backends/backend-A-local-and-remote.txt` | Pending (A is shown working through the edge in C2 and D2) |

## C. Reverse proxy, TLS and load balancing

| ID | Requirement | Command | Observed | Evidence | Status |
|---|---|---|---|---|---|
| C1 | Trusted HTTPS, no `-k` | `curl -v https://app.team67.test:8443/api/status` | `SSL certificate verify ok`; SAN matched; issuer `Team67 Phase1 Local CA`; `HTTP/1.1 200 OK`; `Server: nginx/1.31.6` | `evidence/04_nginx_tls/curl-v-tls-transcript.txt` | Verified |
| C2 | Requests distributed across A and B | 10 × `curl`, print `X-Backend` | `A B A B A B A B A B` from Mac 4; `B A B A B A B A B A` in a second run saved by Sudeshhna | `evidence/04_nginx_tls/load-balance-A-B-run1-from-mac4.txt`, `...run2-sudeshhna.txt` | Verified |
| C3 | Certificate chains to the team CA | `openssl verify -CAfile tls/certs/phase1-ca.crt tls/certs/app.team67.test.crt` | `OK` | `tls/README.md` | Verified |
| C4 | nginx configuration is valid | `nginx -t -c nginx/nginx.conf` | — | `evidence/04_nginx_tls/nginx-t.txt` | Pending |

## D. Caching and transport

| ID | Requirement | Command | Observed | Evidence | Status |
|---|---|---|---|---|---|
| D1 | `Cache-Control` and `ETag` present; conditional GET returns 304 (direct) | `curl -i`, then `curl -i -H 'If-None-Match: "phase1-B-v1"'` against `:3002` | 200 with `max-age=60` and ETag; then `304 Not Modified`, no body | `evidence/05_cache/cache-control-and-304.txt` | Verified |
| D2 | Same through the HTTPS edge | same against `https://app.team67.test:8443/api/status` | 200 from A; conditional with B's ETag routed to B → 304 | same file | Verified |

## E. Packet evidence

| ID | Requirement | Wireshark filter | Frames | Evidence | Status |
|---|---|---|---|---|---|
| E1 | DNS query and response | `dns && dns.qry.name == "app.team67.test"` | 1–4 | `evidence/06_pcaps/phase1-complete-flow.filtered.pcap` | Verified |
| E2 | TCP three-way handshake | `tcp.port == 50490` | 5, 6, 7 | same | Verified |
| E3 | TLS ClientHello, ServerHello, Certificate, ChangeCipherSpec, Finished | `tls && tcp.port == 50490` | 8, 11, 12, 14, 16 | same | Verified |
| E4 | Encrypted application data | same | 18, 29 | same | Verified |
| E5 | Plain HTTP on the edge → backend hop | `tcp.port == 3002` | 20–26 | same | Verified |
| E6 | Annotated screenshots | — | — | `evidence/06_pcaps/screenshots/` | Pending (optional; the frame table in `wireshark/README.md` is the annotation sheet) |

## F. Failure demonstrations

| ID | Fault | Evidence | Status |
|---|---|---|---|
| F1 | Wrong DNS server on client | `evidence/07_failures/01-wrong-dns-server.txt` | Pending |
| F2 | DNS record points to wrong IP | `evidence/07_failures/02-wrong-dns-record.txt` | Pending |
| F3 | One backend stopped | `evidence/07_failures/03-one-backend-down.txt` | Pending |
| F4 | Both backends stopped (502) | `evidence/07_failures/04-both-backends-down.txt` | Pending |
| F5 | Wrong destination port | `evidence/07_failures/05-wrong-port-before-after.txt` | Verified |

## G. Deliverables

| Deliverable | Location | Status |
|---|---|---|
| Architecture document with topology, IP/service table, request flow | `docs/architecture.md`, `docs/ip-service-table.md` | Done (subnet mask / gateway to be added from A1) |
| dnsmasq config | `dns/` | Done |
| nginx config | `nginx/` | Done |
| TLS setup notes | `tls/` | Done (generation commands to be confirmed by edge owner) |
| Backend source and launch instructions | `backend-a/`, `backend-b/` | Done |
| Evidence folder with index | `evidence/INDEX.txt` | Done for collected items |
| Reboot-tested live checkpoint | — | Team to confirm |
