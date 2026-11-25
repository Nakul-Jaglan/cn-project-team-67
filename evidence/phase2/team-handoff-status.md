# Team 67 handoff, 25 November 2026 IST

This is the initial preparation snapshot. The [Phase 2 report](../../docs/phase2-report.md) records the later VPN session and current test status.

## Local readiness

| Role | Observed or reported result | Shared-network work |
|---|---|---|
| Mac 1 and Mac 4 DNS | [Two-Mac transcript](nakul-puneet-rehearsal.txt) shows matching TTL 30 records, backup available during primary downtime, and primary recovery. [Local cache transcript](nakul-local-dns.txt) shows TTL expiry and early refresh after clearing the cache. | Bind both to current demo IPs, load the real app and api records, and record automatic client failover. |
| Mac 2 primary nginx | Sudeshhna reports both project names on TCP 8443, `X-Edge: primary`, existing backend retry settings, and passing `nginx -t` on the Phase 2 copy in her local folder. | Set both upstream IPs, capture final `nginx -t`, and export the Phase 2 config and relevant output for the team repo. |
| Mac 3 Backend A and standby | Neelanshu's handoff contains the Backend A same-Mac transcript (TCP 3001, HTTP 200, `X-Backend: A`) and the standby certificate and nginx transcript. `openssl verify` returned OK and `nginx -t` succeeded at 00:35 IST. For each project hostname, loopback curl on port 8443 verified the certificate and returned HTTP 200 with `X-Edge: standby` and `X-Backend: A`. | Add Mac 4 as upstream B, test Backend A directly from Mac 2, and test the standby from another Mac. The one-Mac backend outage rehearsal used an extra local copy of Backend B before the final certificate was signed. |

The CA SHA-256 fingerprint reported by Sudeshhna matches the tracked `tls/certs/phase1-ca.crt`. Mac 3's received certificate has SANs for `app.team67.test` and `api.team67.test`, with an expiry of 22 February 2027. Private keys remain with their owners.

Mac 2 and Mac 3 reported home Wi-Fi addresses. Recollect all four IPs and interfaces at the demo site. Keep the archived Phase 1 IPs and the current rehearsal address out of the final app records unless reconfirmed for that session.

## Shared session

1. Trade the four live IPs and save the ping matrix. Give Mac 2 the two backend IPs and Nakul's DNS IP. Give Mac 3 the primary edge and Backend B IPs. Nakul and Puneet use the confirmed Mac 2 edge IP for both DNS names.
2. Mac 2 curls A and B directly. From a client, verify trusted HTTPS through the app name and capture six requests with both `X-Backend` values. Verify Mac 3 standby independently before changing DNS.
3. Record the one-backend outage, both-backend 502, restore both, and capture the two Phase 1 DNS fault checks. For backend isolation, use the faculty firewall template or have the project PF anchor attached, then restore the rules after the test.
4. Record automatic DNS failover from a separate client configured with both resolvers. After recovery, run the TTL and standby DNS cutover with both DNS servers in sync. Restore the app DNS record to Mac 2 and verify trusted HTTPS.

If the team cannot use a shared LAN, obtain faculty approval for the alternative topology before collecting final evidence. Confirm the lab's PF procedure in advance if a template or administrator is needed.
