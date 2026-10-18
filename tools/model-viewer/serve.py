#!/usr/bin/env python3
"""Serve only viewer files on loopback; never expose the repository or arbitrary files."""
import argparse
import functools
import http.server
import pathlib
import urllib.parse

ROOT = pathlib.Path(__file__).resolve().parent
ALLOWED = {'index.html', 'src', 'library', 'node_modules', 'probe.html'}

class Handler(http.server.SimpleHTTPRequestHandler):
    def translate_path(self, path):
        decoded = urllib.parse.unquote(urllib.parse.urlsplit(path).path)
        parts = pathlib.PurePosixPath(decoded).parts
        relative = decoded.lstrip('/') or 'index.html'
        target = ROOT / relative
        # node_modules uses pnpm symlinks within this directory. Nothing outside is served.
        if ('..' in parts or '\\' in decoded or not target.resolve().is_relative_to(ROOT)
                or relative.split('/')[0] not in ALLOWED
                or any(part.startswith('.') for part in pathlib.PurePosixPath(relative).parts if part != '.pnpm')):
            return str(ROOT / '__not_served__')
        return str(target)

    def list_directory(self, path):
        self.send_error(404, 'Directory listing disabled')
        return None

    def end_headers(self):
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('Cache-Control', 'no-store')
        self.send_header('Cross-Origin-Resource-Policy', 'same-origin')
        self.send_header('Content-Security-Policy', "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' blob: data:; connect-src 'self' blob: data:; worker-src 'self' blob:; object-src 'none'; base-uri 'none'; frame-ancestors 'none'")
        super().end_headers()

    def do_GET(self):
        # Block DNS rebinding and unexpected hostnames even though the socket is loopback.
        host = self.headers.get('Host', '')
        if host not in {f'127.0.0.1:{self.server.server_port}', f'localhost:{self.server.server_port}'}:
            self.send_error(403, 'Use the loopback URL printed at launch')
            return
        super().do_GET()

    def do_HEAD(self):
        host = self.headers.get('Host', '')
        if host not in {f'127.0.0.1:{self.server.server_port}', f'localhost:{self.server.server_port}'}:
            self.send_error(403)
            return
        super().do_HEAD()

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--port', type=int, default=8766)
    args = parser.parse_args()
    if not (ROOT / 'node_modules/three/build/three.module.js').is_file():
        parser.error('Missing Three.js. Run pnpm install --frozen-lockfile in tools/model-viewer first.')
    try:
        with http.server.ThreadingHTTPServer(('127.0.0.1', args.port), functools.partial(Handler, directory=str(ROOT))) as server:
            print(f'Model viewer: http://127.0.0.1:{server.server_port}', flush=True)
            server.serve_forever()
    except KeyboardInterrupt:
        pass
    except OSError as exc:
        parser.exit(1, f'Cannot start viewer: {exc}\nTry --port with a free local port.\n')

if __name__ == '__main__':
    main()
