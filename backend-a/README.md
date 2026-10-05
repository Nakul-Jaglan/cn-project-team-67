# Backend A

First HTTP backend of the Phase 1 platform.

| Item | Value |
|---|---|
| Owner | Neelanshu |
| Machine | Mac 3 |
| LAN endpoint | `http://10.7.15.25:3001` |
| Bind address | `0.0.0.0:3001` |
| Identity | header `X-Backend: A`, JSON `"backend": "A"` |
| ETag | `"phase1-A-v1"` |

## Launch

```bash
cd backend-a
BACKEND_ID=A PORT=3001 python3 app.py
```

Stop with Ctrl-C in the owning terminal.

## Endpoints

| Request | Response |
|---|---|
| `GET /` | 200 JSON |
| `GET /api/status` | 200 JSON |
| `GET` with `If-None-Match: "phase1-A-v1"` | 304 Not Modified, no body |
| `HEAD /`, `HEAD /api/status` | 200, headers only |
| anything else | 404 |

Every 200/304 carries `X-Backend`, `Cache-Control: public, max-age=60` and `ETag`.

## Verify

```bash
lsof -nP -iTCP:3001 -sTCP:LISTEN
curl -sS -D - http://127.0.0.1:3001/api/status
curl -sS -D - http://10.7.15.25:3001/api/status      # from another Mac
curl -i -H 'If-None-Match: "phase1-A-v1"' http://10.7.15.25:3001/api/status
```

Backend A is behaviourally identical to Backend B; identity and port come from environment variables.
