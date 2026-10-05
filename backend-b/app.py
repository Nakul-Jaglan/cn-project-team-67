from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os

BACKEND = os.environ.get("BACKEND_ID", "A")
PORT = int(os.environ.get("PORT", "3001"))
ETAG = f'"phase1-{BACKEND}-v1"'

class Handler(BaseHTTPRequestHandler):
    def send_common(self, status, length=0):
        self.send_response(status)
        self.send_header("X-Backend", BACKEND)
        self.send_header("Cache-Control", "public, max-age=60")
        self.send_header("ETag", ETAG)
        if length:
            self.send_header("Content-Length", str(length))
        self.end_headers()

    def do_HEAD(self):
        if self.path not in ("/", "/api/status"):
            self.send_error(404)
            return
        self.send_common(200)

    def do_GET(self):
        if self.path not in ("/", "/api/status"):
            self.send_error(404)
            return
        if self.headers.get("If-None-Match") == ETAG:
            self.send_common(304)
            return
        payload = {
            "service": "private-network-phase1",
            "backend": BACKEND,
            "status": "ok",
            "path": self.path,
        }
        body = (json.dumps(payload, indent=2) + "\n").encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("X-Backend", BACKEND)
        self.send_header("Cache-Control", "public, max-age=60")
        self.send_header("ETag", ETAG)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        print(f"[{BACKEND}] {self.client_address[0]} - {fmt % args}", flush=True)

server = ThreadingHTTPServer(("0.0.0.0", PORT), Handler)
print(f"Backend {BACKEND} listening on 0.0.0.0:{PORT}", flush=True)
server.serve_forever()
