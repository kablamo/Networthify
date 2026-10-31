#!/usr/bin/env python3
"""Preview site/ locally, roughly the way Cloudflare Pages serves it.

    python3 site-tests/serve.py [port]

Serves /foo from foo.html, applies the 301s in site/_redirects, and returns
site/404.html for anything missing.  Listens on all interfaces so you can open
it on your phone at http://<this computer's IP>:8000/.
"""
import http.server
import os
import sys
import urllib.parse

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "site")


def load_redirects():
    redirects = {}
    with open(os.path.join(ROOT, "_redirects")) as f:
        for line in f:
            parts = line.split()
            if len(parts) == 3 and not parts[0].startswith("#"):
                redirects[parts[0]] = (parts[1], int(parts[2]))
    return redirects


REDIRECTS = load_redirects()


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def do_GET(self):
        url = urllib.parse.urlsplit(self.path)
        if url.path in REDIRECTS:
            target, status = REDIRECTS[url.path]
            if url.query:
                target += "?" + url.query
            self.send_response(status)
            self.send_header("Location", target)
            self.end_headers()
            return

        path = url.path
        if path.startswith("/_"):
            return self.not_found()
        if not path.endswith("/") and "." not in os.path.basename(path):
            if os.path.isfile(os.path.join(ROOT, path.lstrip("/") + ".html")):
                self.path = path + ".html" + ("?" + url.query if url.query else "")
        file = os.path.join(ROOT, urllib.parse.unquote(self.path.split("?")[0]).lstrip("/"))
        if os.path.isdir(file):
            file = os.path.join(file, "index.html")
        if not os.path.isfile(file):
            return self.not_found()
        return super().do_GET()

    def end_headers(self):
        # never let the browser keep an old stylesheet while you're editing
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def not_found(self):
        with open(os.path.join(ROOT, "404.html"), "rb") as f:
            body = f.read()
        self.send_response(404)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
    print(f"Serving site/ on http://0.0.0.0:{port}/")
    http.server.ThreadingHTTPServer(("", port), Handler).serve_forever()
