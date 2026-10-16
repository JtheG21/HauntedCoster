"""scripts/studio_transfer.py: one request each way, bytes unchanged."""

import binascii
import subprocess
import sys
import tempfile
import time
import unittest
import urllib.request
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "scripts" / "studio_transfer.py"


def _wait_call(fn):
    for _ in range(50):
        try:
            return fn()
        except OSError:
            time.sleep(0.1)
    raise AssertionError("server did not start")


class StudioTransfer(unittest.TestCase):
    def test_receive_then_serve_round_trip(self):
        payload = bytes(range(256)) * 3
        with tempfile.TemporaryDirectory() as d:
            out = Path(d) / "x.rbxm"
            p = subprocess.Popen([sys.executable, "-I", str(SCRIPT), "receive", str(out), "--port", "18765"], stdout=subprocess.PIPE)
            req = urllib.request.Request("http://127.0.0.1:18765/", data=binascii.hexlify(payload), method="POST")
            self.assertEqual(_wait_call(lambda: urllib.request.urlopen(req).read()), b"saved")
            self.assertEqual(p.wait(5), 0)
            self.assertEqual(out.read_bytes(), payload)
            p = subprocess.Popen([sys.executable, "-I", str(SCRIPT), "serve", str(out), "--port", "18766"], stdout=subprocess.PIPE)
            got = _wait_call(lambda: urllib.request.urlopen("http://127.0.0.1:18766/").read())
            self.assertEqual(p.wait(5), 0)
            self.assertEqual(binascii.unhexlify(got), payload)


if __name__ == "__main__":
    unittest.main()
