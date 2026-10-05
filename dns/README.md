# Private DNS — dnsmasq on Mac 1

| Item | Value |
|---|---|
| Owner | Nakul |
| Listen | `127.0.0.1` and `10.7.17.54`, port 53, interface `en0` |
| Zone | `team67.test` is answered locally (`local=/team67.test/`), never forwarded upstream |
| Records | `app.team67.test` → `10.3.1.179`, `api.team67.test` → `10.3.1.179` |
| Query log | `/tmp/cn-phase1-dnsmasq.log` |

Config: [dnsmasq.conf](dnsmasq.conf).

## Run

The exact launch command used on Mac 1 should be confirmed by the owner; the standard form is:

```bash
dnsmasq --test --conf-file="$PWD/dns/dnsmasq.conf"                   # syntax check
sudo dnsmasq --keep-in-foreground --conf-file="$PWD/dns/dnsmasq.conf"
```

Port 53 needs root. If the Mac 1 IP changes, update `listen-address`.

## Point a client at it (and roll back)

```bash
networksetup -getdnsservers "Wi-Fi" | tee original-dns-servers.txt    # save first
sudo networksetup -setdnsservers "Wi-Fi" 10.7.17.54
sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
dig app.team67.test
```

Rollback: `sudo networksetup -setdnsservers "Wi-Fi" <saved servers>` (or `Empty` for DHCP default), then flush the cache again.

## Notes

- `.test` is a reserved namespace; `.local` is avoided because it collides with macOS multicast DNS.
- Answers carry TTL 0 because no `local-ttl` is set, so clients re-query every time. That is convenient for the failure demonstrations (a changed record is visible immediately).
- The `aa` flag in the `dig` output shows dnsmasq answering authoritatively for the local zone.

Evidence: [`evidence/02_dns/dig-client-to-mac1.txt`](../evidence/02_dns/dig-client-to-mac1.txt).
