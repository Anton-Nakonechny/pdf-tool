#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || echo "<your-ip>")

echo "Serving PDF workspace at:"
echo "  http://localhost:10000/PDF-workspace.html"
echo "  http://${LOCAL_IP}:10000/PDF-workspace.html"
echo ""
echo "Press Ctrl-C to stop."

exec python3 - <<'PYEOF'
import http.server, pathlib

HTML = pathlib.Path('PDF-workspace.html').read_bytes()

class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path in ('/', '/PDF-workspace.html'):
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(HTML)))
            self.end_headers()
            self.wfile.write(HTML)
        else:
            self.send_response(302)
            self.send_header('Location', '/')
            self.end_headers()
    def log_message(self, fmt, *args):
        pass

http.server.HTTPServer(('0.0.0.0', 10000), H).serve_forever()
PYEOF
