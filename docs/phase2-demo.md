# Team 67 · Live demo checklist

Use the [Phase 2 report](phase2-report.md) for the topology and the current Tailscale addresses. Open the saved evidence before sharing your screen. Run the client commands below from the repository root on a Mac connected to the Team 67 VPN.

| Order | Presenter | Show |
|---|---|---|
| 1 | Nakul | Topology, four roles, IP addresses and ports |
| 2 | Nakul and team | Ping other Macs and show collected reachability results |
| 3 | Nakul and Neelanshu | Direct queries to both project DNS servers and an ordinary name lookup from Mac 3 |
| 4–5 | Sudeshhna | Verified HTTPS by hostname and six response headers showing A and B |
| 6–7 | Puneet | [DNS, TCP and TLS frames](../wireshark/README.md) and [cache headers with HTTP 304](../evidence/05_cache/cache-control-and-304.txt) |
| 8 | Neelanshu and Sudeshhna | Backend A down, six `200` responses from B, A restarted, both IDs visible again |
| 9 | Nakul and Puneet | [DNS failover](../evidence/phase2/A-dns-failover-vpn.txt), [TTL test](../evidence/phase2/nakul-local-dns.txt) and [standby switch and return](../evidence/phase2/B-E-dns-cutover-vpn.txt). Use the saved transcripts for the timed tests. |
| 10–11 | Everyone | Faculty-injected troubleshooting and individual viva |

## DNS and trusted HTTPS

```sh
dig @100.96.176.78 app.team67.test +time=2 +tries=1
dig @100.97.35.89 app.team67.test +time=2 +tries=1
dig app.team67.test +time=2 +tries=1
curl -v --connect-timeout 3 --max-time 8 \
    --cacert tls/certs/phase1-ca.crt https://app.team67.test:8443/api/status
```

The normal target is `100.98.167.117` with TTL 30. The plain query may show Tailscale’s forwarding address `100.100.100.100` as `SERVER`. In the curl output, look for certificate verification, HTTP 200, `X-Edge: primary` and `X-Backend`.

```sh
for request in 1 2 3 4 5 6; do
    printf '\nRequest %s\n' "$request"
    curl -sS --connect-timeout 3 --max-time 8 \
        --cacert tls/certs/phase1-ca.crt -D - -o /dev/null \
        https://app.team67.test:8443/api/status |
        awk 'tolower($0) ~ /^(http\/|x-backend:|x-edge:)/'
done
```

Coordinate any live outage with the team, test one change at a time and verify recovery afterward. The [report](phase2-report.md) records the firewall test and uncollected evidence as pending.

## Troubleshooting order

1. **DNS.** Compare the system answer with both direct `dig` results. A correct-looking answer can still point to the wrong IP.
2. **TCP.** Run `nc -vz -G 3 100.98.167.117 8443`. If DNS points to the standby by design, test `100.91.79.59` instead. A refusal or timeout can occur before TLS starts.
3. **TLS.** Run the verbose curl above. Check certificate verification, the hostname and the issuing CA.
4. **HTTP.** Read the status and edge header. A `502` after verified TLS calls for nginx upstream logs, followed by a direct check to each backend from the edge. [Both-down example](../evidence/phase2/phase1-both-backends-down-vpn.txt)
