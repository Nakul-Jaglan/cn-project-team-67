# Failure demonstrations

Rule: change one variable at a time, record the symptom, restore the known-good state, prove recovery with a green-path request.

| # | Controlled fault | Owner | Expected observation | Rollback | Saved evidence |
|---|---|---|---|---|---|
| 1 | Wrong DNS server on client | Nakul | `dig app.team67.test` times out or fails; `ping 10.3.1.179` still works | Restore DNS to `10.7.17.54`, flush cache | **Pending** — `evidence/07_failures/01-wrong-dns-server.txt` |
| 2 | DNS record points to wrong IP | Nakul | `dig` succeeds but returns the wrong address; HTTPS fails or reaches the wrong host | Restore `address=/app.team67.test/10.3.1.179`, restart dnsmasq, flush cache | **Pending** — `evidence/07_failures/02-wrong-dns-record.txt` |
| 3 | One backend stopped | Sudeshhna + backend owner | Repeated requests all succeed; only the surviving `X-Backend` value appears | Restart the backend; confirm A and B both return | **Pending** — `evidence/07_failures/03-one-backend-down.txt` |
| 4 | Both backends stopped | Sudeshhna + both backend owners | DNS and TLS still succeed; HTTP status is `502 Bad Gateway` | Restart both backends | **Pending** — `evidence/07_failures/04-both-backends-down.txt` |
| 5 | Wrong destination port | Puneet | DNS and ping succeed; TCP to 9443 is refused | Use the agreed port 8443 | **Saved** — [`05-wrong-port-before-after.txt`](../evidence/07_failures/05-wrong-port-before-after.txt) |

## 5. Wrong destination port (complete)

Run from Mac 4 on Tue 6 Oct 2026 01:12 IST.

| Check | Command | Result |
|---|---|---|
| DNS | `dig app.team67.test` | `NOERROR`, answer `10.3.1.179` |
| Reachability | `ping -c 3 app.team67.test` | 3/3 received, 0.0% loss |
| TCP, wrong port | `nc -vz app.team67.test 9443` | `Connection refused` |
| HTTPS, wrong port | `curl -v --connect-timeout 5 https://app.team67.test:9443/` | `curl: (7) Failed to connect ... Couldn't connect to server` |
| TCP, correct port | `nc -vz app.team67.test 8443` | `succeeded!` |
| HTTPS, correct port | `curl -v https://app.team67.test:8443/api/status` | `SSL certificate verify ok`, `HTTP/1.1 200 OK`, `X-Backend: B` |

In the capture the refusal is a TCP RST from the edge (frames 71–74 in [`wireshark/README.md`](../wireshark/README.md)): the host is alive, but no process listens on 9443.

**Layer statement:** DNS returns the correct edge IP and the host answers ping, but TCP 9443 is closed, so the fault is after DNS and before TLS.

## Commands for the pending demonstrations

Capture each with `script` or `| tee` so the timestamp, command and output are in one file.

```bash
# 1. Wrong DNS server (client)
sudo networksetup -setdnsservers "Wi-Fi" 10.7.17.99        # an address that runs no DNS
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
dig +time=2 +tries=1 app.team67.test                       # expect timeout
ping -c 3 10.3.1.179                                       # still works
sudo networksetup -setdnsservers "Wi-Fi" 10.7.17.54        # rollback
dig app.team67.test

# 2. Wrong record (Mac 1): change the address= line to an unused IP, restart dnsmasq
dig app.team67.test                                        # answers, but wrong IP
curl -v --connect-timeout 5 https://app.team67.test:8443/api/status
# rollback: restore 10.3.1.179, restart dnsmasq, flush client cache, repeat both commands

# 3. One backend down: Ctrl-C Backend A (or B), then from a client
for i in {1..8}; do curl -sS -D - https://app.team67.test:8443/api/status -o /dev/null |
  awk -F': ' 'tolower($1)=="x-backend"{print $2}'; done    # only the survivor
# rollback: restart the backend, repeat the loop, expect A and B

# 4. Both backends down: Ctrl-C both, then
dig app.team67.test
curl -v https://app.team67.test:8443/api/status            # TLS ok, HTTP 502
# rollback: restart both, repeat curl
```
