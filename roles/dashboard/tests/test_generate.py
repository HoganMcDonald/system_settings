import importlib.util
import json
import tempfile
import unittest
from datetime import datetime, timezone
from pathlib import Path


ROLE_ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("dashboard_generate", ROLE_ROOT / "files/generate.py")
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("Unable to load dashboard generator")
generate = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(generate)


class DashboardGeneratorTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        fixture = Path(__file__).parent / "fixtures/dashboard.json"
        cls.payload = json.loads(fixture.read_text())
        cls.model = generate.build_model(cls.payload)

    def test_authored_attention_precedence_and_sorting(self):
        self.assertEqual(
            [pr["status"] for pr in self.model["authored"]],
            ["Changes requested", "Resolve conflicts", "Ready to merge"],
        )

    def test_drafts_are_muted_and_rank_after_actionable_prs(self):
        draft = {
            "isDraft": True,
            "mergeable": "CONFLICTING",
            "mergeStateStatus": "DIRTY",
            "reviewDecision": "CHANGES_REQUESTED",
            "statusCheckRollup": {"state": "FAILURE"},
        }
        self.assertEqual(generate.attention(draft), ("draft", "Draft", 8))
        page = generate.render(self.model, datetime(2026, 8, 7, tzinfo=timezone.utc), 300)
        self.assertIn(".pr-card--draft { border-left-color: var(--muted); opacity: .4; }", page)

    def test_current_review_request_event_is_matched_by_reviewer(self):
        direct, team = self.model["requested"]
        self.assertEqual(direct["requested_at"], "2026-08-01T10:00:00Z")
        self.assertEqual(team["requested_at"], "2026-08-03T09:00:00Z")

    def test_any_human_teammate_review_marks_a_request_covered(self):
        direct, team = self.model["requested"]
        self.assertEqual(direct["other_reviews"], [])
        self.assertEqual(len(team["other_reviews"]), 2)
        self.assertEqual({review["state"] for review in team["other_reviews"]}, {"APPROVED", "COMMENTED"})

    def test_bot_reviews_do_not_mark_a_request_covered(self):
        pr = self.payload["data"]["requested"]["nodes"][0] | {
            "latestReviews": {
                "nodes": [{"author": {"__typename": "Bot", "login": "review-bot"}, "state": "COMMENTED"}]
            }
        }
        normalized = generate.normalize_pr(pr, "Me", set(), True)
        self.assertEqual(normalized["other_reviews"], [])

    def test_render_escapes_pr_content_and_marks_covered_rows(self):
        page = generate.render(self.model, datetime(2026, 8, 7, tzinfo=timezone.utc), 300)
        self.assertIn("Escape &lt;script&gt;alert(1)&lt;/script&gt;", page)
        self.assertNotIn("Escape <script>alert(1)</script>", page)
        self.assertIn("pr-card--handled", page)
        self.assertIn("Reviewed by 2 others", page)
        self.assertIn('localStorage.getItem("dashboard-theme") || "dark"', page)
        self.assertNotIn("DASH<br>BOARD", page)
        self.assertNotIn("local view of work", page)

    def test_local_comments_use_jawbones_and_prune_before_saving(self):
        page = generate.render(self.model, datetime(2026, 8, 7, tzinfo=timezone.utc), 300)
        self.assertIn('class="jawbone"', page)
        self.assertIn('const commentStorageKey = "dashboard-pr-comments"', page)
        self.assertIn(".slice(0, 49)", page)
        self.assertIn("body.textContent = comment.body", page)

    def test_fixture_can_generate_a_page_without_github(self):
        fixture = Path(__file__).parent / "fixtures/dashboard.json"
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "index.html"
            result = generate.main(["--input", str(fixture), "--output", str(output), "--state-dir", directory])
            self.assertEqual(result, 0)
            self.assertTrue(output.read_text().startswith("<!doctype html>"))


if __name__ == "__main__":
    unittest.main()
