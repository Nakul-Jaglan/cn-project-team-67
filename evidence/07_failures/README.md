# Failure demonstrations

| File | Fault | Status |
|---|---|---|
| `01-wrong-dns-server.txt` | Wrong DNS server on client | Pending (Nakul) |
| `02-wrong-dns-record.txt` | DNS record points to wrong IP | Pending (Nakul) |
| `03-one-backend-down.txt` | One backend stopped | Pending (Sudeshhna + backend owner) |
| `04-both-backends-down.txt` | Both backends stopped, 502 | Pending (Sudeshhna + both backend owners) |
| `05-wrong-port-before-after.txt` | Wrong destination port | Saved |

Commands, expected symptoms and rollback steps: [`docs/failure-demos.md`](../../docs/failure-demos.md).
