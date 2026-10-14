import importlib.util
import sys
import unittest
from pathlib import Path

SPEC = importlib.util.spec_from_file_location(
    "watch_chunked", Path(__file__).resolve().parents[1] / "scripts" / "watch_chunked.py")
wc = importlib.util.module_from_spec(SPEC)
sys.modules["watch_chunked"] = wc
SPEC.loader.exec_module(wc)

OK = "# watch\n\n## Answer (from Gemini)\n\n_These are Gemini's observations of the video, not frames._\n\nRule one.\n\n## Other\nignored"
BUSY = "## Unavailable evidence\n\n- Gemini service: server error. Detail: HTTP 503: high demand"
QUOTA = "- Gemini quota: rate limited. Detail: HTTP 429: Rate limit exceeded (limit: 20 requests per day on Free Tier)"
MINUTE = "- Gemini quota: rate limited. Detail: HTTP 429: too many requests, retry in 30s"
REJECT = "- Gemini rejected: refused. Detail: HTTP 400: Agentic video processing is not enabled"


class TimestampTests(unittest.TestCase):
    def test_parse_and_format(self):
        self.assertEqual(wc.parse_ts("90"), 90)
        self.assertEqual(wc.parse_ts("1:30"), 90)
        self.assertEqual(wc.parse_ts("1:02:03"), 3723)
        self.assertEqual(wc.fmt_ts(90), "1:30")
        self.assertEqual(wc.fmt_ts(3723), "1:02:03")

    def test_bad_timestamp(self):
        with self.assertRaises(ValueError):
            wc.parse_ts("a:b")


class PlanTests(unittest.TestCase):
    def test_even_split(self):
        self.assertEqual(wc.plan_segments(0, 600, 300), [(0, 300), (300, 600)])

    def test_tiny_tail_is_merged(self):
        self.assertEqual(wc.plan_segments(0, 610, 300), [(0, 300), (300, 610)])

    def test_real_tail_is_kept(self):
        self.assertEqual(wc.plan_segments(0, 1658, 300)[-1], (1500, 1658))

    def test_segments_cover_range_without_gaps(self):
        segs = wc.plan_segments(45, 1000, 240)
        self.assertEqual(segs[0][0], 45)
        self.assertEqual(segs[-1][1], 1000)
        for a, b in zip(segs, segs[1:]):
            self.assertEqual(a[1], b[0])

    def test_invalid(self):
        with self.assertRaises(ValueError):
            wc.plan_segments(10, 10, 300)
        with self.assertRaises(ValueError):
            wc.plan_segments(0, 100, 0)


class ClassifyTests(unittest.TestCase):
    def test_ok(self):
        self.assertEqual(wc.classify(OK), "ok")

    def test_retryable(self):
        self.assertEqual(wc.classify(BUSY), "retry")
        self.assertEqual(wc.classify(MINUTE), "retry")

    def test_daily_quota_stops(self):
        self.assertEqual(wc.classify(QUOTA), "quota")

    def test_fatal(self):
        self.assertEqual(wc.classify(REJECT), "fatal")
        self.assertEqual(wc.classify("error: GEMINI_API_KEY missing"), "fatal")

    def test_extract_answer_drops_boilerplate_and_next_sections(self):
        self.assertEqual(wc.extract_answer(OK), "Rule one.")
        self.assertEqual(wc.extract_answer(BUSY), "")
        self.assertEqual(wc.extract_answer(OK + "\n[watch] asking gemini"), "Rule one.")


class ReportTests(unittest.TestCase):
    def test_report_lists_failures_without_fallback(self):
        results = [
            {"span": (0, 300), "ok": True, "answer": "A", "attempts": 1},
            {"span": (300, 600), "ok": False, "reason": "503", "attempts": 4},
        ]
        text = wc.build_report("https://example.test/v", "q", results, "gemini-3.7-flash")
        self.assertIn("1 answered, 1 failed", text)
        self.assertIn("Failed segments", text)
        self.assertIn("No fallback was attempted", text)


if __name__ == "__main__":
    unittest.main()
