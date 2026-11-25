# Phase 2 nginx configuration

These templates reproduce the demo routing and retry settings. The primary template is based on the Phase 1 config and the Phase 2 settings shared by Sudeshhna. The standby template comes from Neelanshu’s handoff with Backend B set to its Tailscale address. The team tested the running configurations on their respective Macs.

| Template | Run on | Backend A | Backend B | Response header |
|---|---|---|---|---|
| [primary.conf.template](primary.conf.template) | Mac 2 | `100.91.79.59:3001` | `100.97.35.89:3002` | `X-Edge: primary` |
| [standby.conf.template](standby.conf.template) | Mac 3 | `127.0.0.1:3001` | `100.97.35.89:3002` | `X-Edge: standby` |

1. Copy the applicable template to a working `nginx.conf`. On the primary, replace `@PRIMARY_CERT@` and `@PRIMARY_KEY@` with the absolute paths to the certificate and private key. On the standby, replace `@STANDBY_DIR@` with the absolute path to its writable config directory containing `standby.crt` and `standby.key`.
2. Verify that the certificate covers `app.team67.test` and `api.team67.test` and chains to the [Team 67 CA](../../tls/certs/phase1-ca.crt). Follow the [TLS setup notes](../../tls/README.md) for trust setup. Each edge owner keeps their private key locally.
3. Run `nginx -t -c /absolute/path/to/nginx.conf` using the rendered config. Use that same config to start nginx on the corresponding Mac. Keep a backup of the working config before making changes to a running edge.

Both edges listen on TCP 8443. They use passive failover with `max_fails=1`, `fail_timeout=5s`, and up to two upstream attempts. The primary access log records the sequence of upstream addresses and statuses for each request. The [live demo checklist](../../docs/phase2-demo.md) shows how to identify the edge and backend from a client.
