# Backend B

Second HTTP backend of the Phase 1 platform. Mac 4 also acts as the test client and capture host.

| Item | Value |
|---|---|
| Owner | Puneet |
| Machine | Mac 4 |
| LAN endpoint | `http://10.7.21.130:3002` |
| Bind address | `0.0.0.0:3002` |
| Identity | header `X-Backend: B`, JSON `"backend": "B"` |
| ETag | `"phase1-B-v1"` |
| Runtime used | Python 3.12.4 (standard library only) |

## Launch

```bash
cd backend-b
BACKEND_ID=B PORT=3002 python3 app.py | tee backend-B.log
```

The startup line must read `Backend B listening on 0.0.0.0:3002`. Stop with Ctrl-C.

## Endpoints

| Request | Response |
|---|---|
| `GET /` | 200 JSON |
| `GET /api/status` | 200 JSON |
| `GET` with `If-None-Match: "phase1-B-v1"` | 304 Not Modified, no body |
| `HEAD /`, `HEAD /api/status` | 200, headers only |
| anything else | 404 |

## Verify

```bash
lsof -nP -iTCP:3002 -sTCP:LISTEN
curl -sS -D - http://127.0.0.1:3002/api/status
curl -sS -D - http://10.7.21.130:3002/api/status ; nc -vz 10.7.21.130 3002   # from another Mac
curl -i -H 'If-None-Match: "phase1-B-v1"' http://10.7.21.130:3002/api/status
```

## Evidence

- Local and remote tests: [`evidence/03_backends/backend-B-local-and-remote.txt`](../evidence/03_backends/backend-B-local-and-remote.txt)
- Server log showing requests arriving from the edge `10.3.1.179`: [`evidence/03_backends/backend-B-server-log.txt`](../evidence/03_backends/backend-B-server-log.txt)
- Caching: [`evidence/05_cache/cache-control-and-304.txt`](../evidence/05_cache/cache-control-and-304.txt)

Direct backend requests are diagnostic only. In the real flow clients use `https://app.team67.test:8443/` and never type a backend IP.
