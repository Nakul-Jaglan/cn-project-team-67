# Team 67 Phase 2 DNS

Mac 1 (Nakul) is the primary resolver. Mac 4 (Puneet) is the backup. Both use this configuration with their own current Wi-Fi IP and identical DNS records. The lab resolver serves `team67.test` locally and does not forward internet queries.

For the faculty-approved remote demo, use the [Tailscale setup and VPN binding instructions](tailscale.md).

## Rehearse with Nakul and Puneet

1. Confirm the two current IPs and ping both ways. On Nakul's Mac, use `sh phase2/dns/run.sh en0 53 phase2/dns/rehearsal.hosts` from the repository. Enter the macOS administrator password when prompted and leave that Terminal open. The resolver binds to Nakul's address and returns the record in `rehearsal.hosts`, currently `10.7.18.80 dnscheck.team67.test`.
2. On Puneet's Mac, run `dig @10.7.26.120 dnscheck.team67.test` using Nakul's current IP. The answer should be **Puneet's IP** with TTL 30. The `SERVER` line should show **Nakul's IP** on port 53. Save the output with a timestamp.
3. Start Puneet's own backup DNS config with the same record and `local-ttl=30`. From Nakul's Mac, run `dig @10.7.18.80 dnscheck.team67.test` using Puneet's current IP. The answer should match Mac 1's answer, and the `SERVER` line should show **Puneet's IP** on port 53.
4. Use a separate Terminal for queries. `Ctrl-C` in the resolver Terminal stops that instance. If permission or a firewall prevents the port-53 rehearsal, use a test listener on port 1053 with the same hosts file and add `-p 1053` to explicit `dig` queries. Use port 53 for the configured-client failover test.

For a record reload, edit the hosts file and send HUP as shown below. Query each server directly in separate `dig` commands to check the new answer and TTL. To rehearse an outage, stop Mac 1 and confirm that Mac 4 still answers a direct query. For automatic failover proof, use a separate client configured with both resolvers on port 53.

### If dnsmasq cannot read the hosts file

On macOS, the port-53 process drops privileges after binding, and its service account may have no access to files under Desktop or a private home directory. A syntax check can pass even when the running daemon cannot read `addn-hosts`. Stop the current test instance, then create a readable temporary copy of the DNS records:

```sh
runtime_dir=$(mktemp -d /private/tmp/team67-dns.XXXXXX)
chmod 755 "$runtime_dir"
install -m 644 phase2/dns/rehearsal.hosts "$runtime_dir/rehearsal.hosts"
printf 'Live hosts file: %s/rehearsal.hosts\n' "$runtime_dir"
sh phase2/dns/run.sh en0 53 "$runtime_dir/rehearsal.hosts"
```

For HUP exercises, edit the printed live file and keep it readable. For the integrated demo, stage the actual app and api hosts file the same way. Store only project DNS records in this directory.

Direct `dig` tests need no Wi-Fi DNS setting changes. Mac 1's last observed `en0` address was `10.7.26.120` on 24 Nov 2026. Read the address printed by the launcher for the current session.

## Switch to the real app on the demo network

Once all four roles share the chosen private network, record their live IPs, interfaces, masks, gateways and ping results. The October configuration has historical addresses. From Mac 2, verify that both backends answer before running the full DNS and HTTPS checks.

On both DNS Macs, create a working copy of `team67.hosts.example` and replace both `EDGE_IP` tokens with Mac 2's current IP. Restart each resolver in its Terminal using this file:

```sh
sh phase2/dns/run.sh en0 53 /absolute/path/to/team67.hosts
```

Use the same initial files on both resolvers. From a client, query both resolvers directly and compare the app and api records, then configure the demo client to use the primary and backup DNS IPs, saving its original settings first. Other names may fail while the client uses these lab resolvers. An active connection to either server on port 53 is required for its queries to work.

### A. DNS failover

1. Verify application DNS and trusted HTTPS through port 8443 with both resolvers up.
2. Stop Mac 1's resolver using `Ctrl-C`. Clear the client DNS cache, then run a plain `dig app.team67.test` and a fresh trusted HTTPS request by name. Save the output and a capture or backup query log showing Mac 4 answered. An explicit `dig @PUNEET_IP` establishes reachability but does not demonstrate automatic resolver selection.
3. Restart Mac 1's resolver and verify both resolvers answer. At the end of the demo restore the original client DNS list, or `Empty` with `networksetup -setdnsservers` if it was automatic.

### B and E. TTL and edge cutover

1. Validate trusted HTTPS to both edges. Prime a client lookup for `app.team67.test` pointing to the primary edge. Note the time. Leave both nginx instances running; back out any primary-only isolation rules before this test.
2. Change just the app row to the standby edge IP in both working hosts files. On each DNS server, identify and reload its process:

   ```sh
   dns_pid=$(cat "${TMPDIR:-/tmp}/team67-dnsmasq-53.pid")
   ps -p "$dns_pid" -o pid,command
   # Once the command shows this project's config:
   sudo kill -HUP "$dns_pid"
   ```

3. Direct queries to the resolvers should immediately show the new address. From the normal demo client, use fresh curl commands with `-w 'edge=%{remote_ip}\n'` and record when it reaches the standby. A client with the old answer cached may keep using the primary until the 30-second TTL expires. Repeat with a fresh old cache entry and clear the cache manually to show the early refresh. If macOS refreshes immediately, use the explicit test cache in Nakul's PDF for the TTL observation and show the HTTPS cutover separately.
4. Restore the app record to the primary edge on both servers and send HUP again. Clear the client cache and verify the app opens via Mac 2. Leave the api record unchanged through the exercise.

## Phase 1 prerequisites and fault evidence

Keep `dns/dnsmasq.conf` and the October evidence as the historical baseline. Save the new LAN inventory and a client DNS + trusted HTTPS transcript once the real edge is reachable. Separately collect the wrong-resolver and wrong-app-record failure and recovery evidence. For the wrong-record exercise, use one test resolver so a second resolver cannot mask the change. Restore the correct app record and the original client resolver settings after each fault.

See `evidence/phase2/nakul-local-dns.txt` for the one-Mac rehearsal. A same-Mac query, local cache test or rehearsal hostname is separate from the live four-role evaluation.
