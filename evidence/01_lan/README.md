# LAN inventory — pending

Owner: Nakul, with all four Macs present.

Files expected here:

- `ip-inventory.txt` — for each Mac: `ipconfig getifaddr en0`, `networksetup -getinfo "Wi-Fi"` (IP, subnet mask, router), `route -n get default | egrep 'gateway|interface'`
- `ping-matrix.txt` — `ping -c 3 <IP>` from every Mac to the other three

Once collected, copy subnet mask and gateway into `docs/ip-service-table.md`.
