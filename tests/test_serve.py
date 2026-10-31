"""scripts/serve.sh: serves the active game and refuses to start beside another listener."""

import socket
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def free_port() -> int:
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def run(*args):
    return subprocess.run([str(ROOT / "scripts" / "serve.sh"), *args], capture_output=True, text=True)


class Serve(unittest.TestCase):
    def test_bad_argument(self):
        self.assertEqual(run("--nope").returncode, 2)

    def test_refuses_a_busy_port_and_names_the_process(self):
        with socket.socket() as s:
            s.bind(("127.0.0.1", 0))
            s.listen()
            r = run("--port", str(s.getsockname()[1]), "--dry-run")
        self.assertEqual(r.returncode, 1)
        self.assertIn("PID", r.stderr)

    def test_dry_run_names_the_active_project(self):
        listening = subprocess.run(["lsof", "-nP", "-c", "rojo", "-a", "-iTCP", "-sTCP:LISTEN", "-t"],
                                   capture_output=True, text=True).stdout.strip()
        if listening:
            self.skipTest("a Rojo server is running on this machine")
        env = dict(line.split("=", 1) for line in (ROOT / "scripts" / "active-game.env").read_text().splitlines()
                   if "=" in line and not line.startswith("#"))
        r = run("--port", str(free_port()), "--dry-run")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn(env["ACTIVE_GAME_PROJECT"], r.stdout)


if __name__ == "__main__":
    unittest.main()
