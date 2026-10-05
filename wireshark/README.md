# Packet evidence — annotated capture

| Item | Value |
|---|---|
| Capture file | [`evidence/06_pcaps/phase1-complete-flow.filtered.pcap`](../evidence/06_pcaps/phase1-complete-flow.filtered.pcap) (116 frames) |
| SHA-256 | `5ce84174620f7e1faaea54331896add7e20f875ab49f45f0c0e84cb456333aa3` |
| Captured on | Mac 4 (`10.7.21.130`), interface `en0`, Tue 6 Oct 2026 01:12 IST |
| Commands run during capture | [`evidence/06_pcaps/capture-terminal-transcript.txt`](../evidence/06_pcaps/capture-terminal-transcript.txt) |

**About the filter.** The original capture (277 frames, SHA-256 `fdc008d8…66f9824`) also contained unrelated background traffic from the capture laptop. Because this repository is public, the published file keeps only frames to or from the edge `10.3.1.179` and DNS frames for `team67.test`. No frame was modified; payloads and timestamps are byte-identical. The original is kept offline, unmodified. **Frame numbers below refer to the filtered file.**

Endpoints: client/Backend B = `10.7.21.130`, DNS = `10.7.17.54`, edge = `10.3.1.179`.

## 1. DNS (UDP 53)

Filter: `dns && dns.qry.name == "app.team67.test"`

| Frame | Time | Source → Destination | What it is | What it proves |
|---|---|---|---|---|
| 1 | 01:12:14.746 | `10.7.21.130:54056` → `10.7.17.54:53` | A query, id `0xfba9` (from `dig`) | Client asks the team DNS server, from an ephemeral UDP port |
| 2 | 01:12:14.751 | `10.7.17.54:53` → `10.7.21.130:54056` | Response, A = `10.3.1.179` | Mac 1 answers for the private zone with the edge IP |
| 3 | 01:12:14.780 | `10.7.21.130:51699` → `10.7.17.54:53` | A query, id `0x1828` (system resolver, for `curl`) | The HTTPS client resolves the name before connecting |
| 4 | 01:12:14.785 | `10.7.17.54:53` → `10.7.21.130:51699` | Response, A = `10.3.1.179` | The answer is the edge IP |

The first TCP SYN (frame 5) leaves 1.4 ms after the DNS answer in frame 4: TCP cannot start until DNS has supplied the destination address.

## 2. TCP three-way handshake (stream `10.7.21.130:50490` ↔ `10.3.1.179:8443`)

Filter: `tcp.port == 50490`

| Frame | Direction | Flags | Seq / Ack | Meaning |
|---|---|---|---|---|
| 5 | client → edge | SYN | seq 3328525446 | Client opens the connection and announces its initial sequence number. No application data yet |
| 6 | edge → client | SYN, ACK | seq 1136226980, ack 3328525447 | Edge acknowledges client ISN + 1 and announces its own ISN |
| 7 | client → edge | ACK | seq 3328525447, ack 1136226981 | Client acknowledges edge ISN + 1. Connection established |

Socket pair: (`10.7.21.130`, 50490, `10.3.1.179`, 8443, TCP). Port 50490 is the client's ephemeral port; 8443 is the service port.

## 3. TLS 1.2 handshake (same stream, forced with `curl --tlsv1.2 --tls-max 1.2`)

Filter: `tls && tcp.port == 50490`

| Frame | Direction | TLS message(s) | Meaning |
|---|---|---|---|
| 8 | client → edge | ClientHello, SNI = `app.team67.test` | Client offers versions and cipher suites and names the host it wants |
| 11 | edge → client | ServerHello, Certificate, ServerKeyExchange (starts) | Edge picks parameters and sends its certificate (1147-byte record, in clear in TLS 1.2) |
| 12 | edge → client | ServerKeyExchange (continues), ServerHelloDone | ECDHE parameters signed by the server key |
| 14 | client → edge | ClientKeyExchange, ChangeCipherSpec, Finished (encrypted) | Client's ECDHE share; switches to the negotiated keys |
| 16 | edge → client | ChangeCipherSpec, Finished (encrypted) | Edge switches to encrypted mode. Handshake complete |
| 18 | client → edge | Application Data (109 bytes) | The HTTP `GET /api/status` request, encrypted |
| 29 | edge → client | Application Data (344 bytes) | The HTTP 200 response, encrypted |
| 33 | client → edge | Encrypted Alert | `close_notify` |
| 34, 38 | both | FIN, then RST | Connection teardown |

Negotiated suite, from the curl transcript: `TLSv1.2 / ECDHE-RSA-CHACHA20-POLY1305`.

The HTTP request and response are not readable in frames 18 and 29. The HTTP status and headers for this exact request are in the curl transcript: `HTTP/1.1 200 OK`, `X-Backend: B`, `Cache-Control: public, max-age=60`, `ETag: "phase1-B-v1"`.

## 4. The second hop: nginx → Backend B in plain HTTP

Because Mac 4 is both the capture host and Backend B, the same capture also contains the edge-to-backend leg of the same request.

Filter: `tcp.port == 3002`

| Frame | Direction | Content | Meaning |
|---|---|---|---|
| 20–22 | `10.3.1.179:58020` ↔ `10.7.21.130:3002` | SYN, SYN-ACK, ACK | nginx opens its own, separate TCP connection to the backend |
| 23 | edge → B | `GET /api/status HTTP/1.1` (readable) | Request forwarded as plain HTTP |
| 25 | B → edge | `HTTP/1.0 200 OK`, `X-Backend: B` (readable) | Backend response headers in clear text |
| 26 | B → edge | JSON body, FIN | Body in clear text; backend closes |

Ordering shows the proxying: encrypted request arrives (frame 18) → nginx contacts the backend (20–26) → encrypted response leaves (29). TLS protects the client–edge link only; it is terminated at nginx.

## 5. TLS 1.3 for comparison (stream `50491` ↔ `8443`)

| Frame | Direction | TLS message(s) |
|---|---|---|
| 35, 39, 40 | — | SYN, SYN-ACK, ACK |
| 41 | client → edge | ClientHello, SNI = `app.team67.test` |
| 43 | edge → client | ServerHello, ChangeCipherSpec (compatibility), then only Application Data records |
| 46–48 | client → edge | ChangeCipherSpec (compatibility), Application Data |

In TLS 1.3 everything after ServerHello is encrypted, including the certificate (it travels inside the 1167-byte Application Data record in frame 43). That is why the TLS 1.2 request was forced: it makes Certificate and ChangeCipherSpec/Finished individually visible, as the brief asks. Normal service still negotiates TLS 1.3.

## 6. Wrong-port failure in the same capture

Filter: `tcp.port == 9443 || icmp`

| Frame | Direction | Content | Meaning |
|---|---|---|---|
| 63–64 | client ↔ DNS | Query and answer for `app.team67.test` | DNS works |
| 65–70 | client ↔ edge | 3 × ICMP echo request/reply | Host is reachable |
| 71 | client → edge:9443 | SYN | Connection attempt to a port with no listener |
| 72 | edge → client | RST, ACK | Edge kernel refuses: "Connection refused" |
| 73–74 | same | SYN, then RST, ACK | Second attempt (`curl`), same result |
| 75–77 | client ↔ edge:8443 | SYN, SYN-ACK, ACK | Correct port: handshake succeeds |
| 83–116 | client ↔ edge:8443 | Full TLS 1.3 request | Recovery proved |

Diagnosis: name resolution and IP reachability are fine, the fault is at the transport layer (no service on that port). Terminal output: [`evidence/07_failures/05-wrong-port-before-after.txt`](../evidence/07_failures/05-wrong-port-before-after.txt).

## Reproducing the frame list without Wireshark

```bash
tcpdump -nn -r evidence/06_pcaps/phase1-complete-flow.filtered.pcap
tcpdump -nn -A -r evidence/06_pcaps/phase1-complete-flow.filtered.pcap 'tcp port 3002'
```
