#!/usr/bin/env python3
"""网页版本地服务器：python3 tools/serve_web.py [端口]（默认 8060）
带 COOP/COEP 跨域隔离头，Chrome/Safari/Firefox 都能跑。"""
import http.server
import sys
import os

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8060
ROOT = os.path.join(os.path.dirname(__file__), "..", "export", "web")


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


if __name__ == "__main__":
    with http.server.HTTPServer(("", PORT), Handler) as httpd:
        print(f"网页版已启动: http://localhost:{PORT}")
        httpd.serve_forever()
