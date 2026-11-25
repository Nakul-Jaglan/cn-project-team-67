# Team 67 remote demo over Tailscale

Use one private tailnet for the four Macs. Tailscale provides the routes between them. The team still runs dnsmasq, primary and standby nginx, both backends, and the project CA. The service names and TLS port stay the same.

## Join and collect addresses

1. Nakul installs [Tailscale for macOS](https://tailscale.com/docs/install/mac), signs in, and approves macOS's VPN prompt. Use a tailnet dedicated to the project. Under [Users in the admin console](https://console.tailscale.com/admin/users), use [Invite external users](https://tailscale.com/docs/features/sharing/how-to/invite-any-user) to send Puneet, Neelanshu, and Sudeshhna separate invitations as Members. Each teammate signs in with their own account.
2. Record each Mac's Tailscale IPv4 from the menu or the admin console's Machines page. Assign `DNS1_IP` to Nakul, `EDGE_IP` to Sudeshhna, `A_IP` and `STANDBY_IP` to Neelanshu, and `B_IP` and `DNS2_IP` to Puneet. These are the demonstrable addresses on this topology. Have each Mac save its pings to the others or document blocked ICMP and verify the actual service connections.
3. Test before changing DNS. Mac 2 should directly reach A on port 3001 and B on 3002. Update its nginx upstreams to the VPN IPs. Mac 3 keeps its local A upstream at `127.0.0.1:3001` and adds B's VPN IP. Verify both HTTPS edges on TCP 8443 from another Mac using the team CA and `curl --resolve` for the initial diagnostic.

## Serve the private names on the VPN

On both DNS Macs, open a terminal in the repo. Enter the **VPN IPv4 of the primary edge** and **this Mac's own VPN IPv4** when prompted. Stage a readable hosts file so dnsmasq can still read it after dropping privileges.

```sh
printf 'Sudeshhna’s primary edge VPN IPv4: '
read -r edge_ip
printf 'This Mac’s VPN IPv4: '
read -r TEAM67_VPN_IP
export TEAM67_VPN_IP
runtime_dir=$(mktemp -d /private/tmp/team67-vpn-dns.XXXXXX)
chmod 755 "$runtime_dir"
sed "s/EDGE_IP/$edge_ip/g" phase2/dns/team67.hosts.example > "$runtime_dir/team67.hosts"
chmod 644 "$runtime_dir/team67.hosts"
printf 'Live hosts file: %s/team67.hosts\n' "$runtime_dir"
```

Stop the existing project instance if it is still using port 53. Use its serving Terminal or send TERM to its confirmed PID. In the same shell as the staging command, run:

```sh
sh phase2/dns/run.sh vpn 53 "$runtime_dir/team67.hosts"
```

The launcher checks that `TEAM67_VPN_IP` is assigned to an active macOS `utun` interface and binds to that address plus loopback. Send UDP and TCP DNS queries from a different Mac to each VPN resolver. Confirm both names return the primary edge VPN IP with TTL 30. If the VPN reconnects, verify the current tunnel interface before rerunning the demo.

Once the direct queries pass, configure only `team67.test` to use both resolvers through [restricted nameservers](https://tailscale.com/docs/reference/dns-in-tailscale). Keep general internet DNS on its usual path. Verify with the system resolver (`dscacheutil -q host -a name app.team67.test`) and curl by hostname. Use a resolver log or packet capture to show which DNS server answered. The VPN client may query both resolvers without a fixed order. With Mac 1 stopped, a new OS lookup and HTTPS request plus a reply from Mac 4 proves continued service.

For backend isolation, write rules for the actual VPN traffic path using Mac 2's VPN IP as the allowed source. Verify from both Mac 2 and an ordinary client. Confirm the firewall observes traffic on the discovered interface and restore the rules before the cutover. Use the faculty template or agreed test procedure if PF does not see the traffic with the installed Tailscale variant.

Keep the private app URL at `https://app.team67.test:8443/`. No public tunnel, public DNS entry, certificate replacement, or exit node is needed.
