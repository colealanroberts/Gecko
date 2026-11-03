"""Run Swift tests against a local HTTP fixture; no Nvidia/GitHub requests."""
import http.server
import os
from pathlib import Path
import subprocess
import sys
import threading
import time


class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def do_GET(self):
        if self.path == '/error':
            self.send_response(503)
            self.end_headers()
            return
        payload = b'x' * 2_200_123
        self.send_response(200)
        if self.path != '/unknown':
            self.send_header('Content-Length', str(len(payload)))
        self.end_headers()
        try:
            for offset in range(0, len(payload), 33_333):
                self.wfile.write(payload[offset:offset + 33_333])
                self.wfile.flush()
                if self.path == '/slow':
                    time.sleep(0.02)
        except (BrokenPipeError, ConnectionResetError, ConnectionAbortedError):
            pass


if __name__ == '__main__':
    server = http.server.ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    env = dict(os.environ, GECKO_TEST_SERVER=f'http://127.0.0.1:{server.server_port}')
    try:
        result = subprocess.run(['swift', 'test', *sys.argv[1:]],
                                cwd=Path(__file__).resolve().parent.parent, env=env)
    finally:
        server.shutdown()
        server.server_close()
    sys.exit(result.returncode)
