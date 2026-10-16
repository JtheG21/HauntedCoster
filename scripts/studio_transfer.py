"""One-shot local file transfer between Roblox Studio (Studio MCP execute_luau) and this Mac.

Studio scripts can't write files, so an instance tree is serialised in Studio and posted here as hex text,
or a local .rbxm is served for Studio to fetch and deserialise. Binds 127.0.0.1 only, handles exactly one
request, then exits.

  python3 -I scripts/studio_transfer.py receive <out.rbxm> [--port 8765]   # Studio POSTs hex -> file
  python3 -I scripts/studio_transfer.py serve <in.rbxm> [--port 8766]      # Studio GETs hex <- file

The Luau side (SerializationService + HttpService, with HttpEnabled turned on only for the call and restored)
is in .claude/skills/art-import/SKILL.md.
"""

import argparse
import binascii
import http.server
import sys


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("mode", choices=["receive", "serve"])
    p.add_argument("path")
    p.add_argument("--port", type=int)
    a = p.parse_args()
    port = a.port or (8765 if a.mode == "receive" else 8766)
    data = binascii.hexlify(open(a.path, "rb").read()) if a.mode == "serve" else b""

    class Handler(http.server.BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass

        def do_POST(self):
            if a.mode != "receive":
                self.send_error(405)
                return
            raw = self.rfile.read(int(self.headers["Content-Length"])).strip()
            with open(a.path, "wb") as f:
                f.write(binascii.unhexlify(raw))
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b"saved")
            print(f"saved {len(raw) // 2} bytes to {a.path}")

        def do_GET(self):
            if a.mode != "serve":
                self.send_error(405)
                return
            self.send_response(200)
            self.end_headers()
            self.wfile.write(data)
            print(f"served {len(data) // 2} bytes from {a.path}")

    http.server.HTTPServer(("127.0.0.1", port), Handler).handle_request()
    return 0


if __name__ == "__main__":
    sys.exit(main())
