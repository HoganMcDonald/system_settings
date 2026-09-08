import importlib.util
import unittest
from datetime import datetime, timezone
from pathlib import Path
from zoneinfo import ZoneInfo


ROLE_ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("github_gtd_sync", ROLE_ROOT / "files/sync.py")
if SPEC is None or SPEC.loader is None:
    raise RuntimeError("Unable to load GitHub GTD synchronizer")
sync = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(sync)


def pr(**overrides):
    value = {
        "id": "PR_node_1",
        "number": 123,
        "title": "Make the change",
        "url": "https://github.com/acme/app/pull/123",
        "createdAt": "2026-08-27T19:00:00Z",
        "updatedAt": "2026-08-28T19:00:00Z",
        "isDraft": False,
        "mergeable": "MERGEABLE",
        "mergeStateStatus": "CLEAN",
        "reviewDecision": "REVIEW_REQUIRED",
        "author": {"login": "alice"},
        "repository": {"nameWithOwner": "acme/app"},
        "statusCheckRollup": {"state": "SUCCESS"},
        "reviews": {"totalCount": 1},
        "reviewRequests": {"nodes": []},
        "timelineItems": {"nodes": []},
    }
    value.update(overrides)
    return value


class GitHubGtdSyncTest(unittest.TestCase):
    def test_sla_skips_weekend_and_keeps_local_time(self):
        eastern = ZoneInfo("America/New_York")
        requested = datetime(2026, 8, 28, 15, tzinfo=eastern)
        due = sync.add_weekday_hours(requested, 24, eastern)
        self.assertEqual(due, datetime(2026, 8, 31, 15, tzinfo=eastern))

    def test_sla_skips_dst_weekend(self):
        eastern = ZoneInfo("America/New_York")
        requested = datetime(2026, 3, 6, 15, tzinfo=eastern)
        due = sync.add_weekday_hours(requested, 24, eastern)
        self.assertEqual(due, datetime(2026, 3, 9, 15, tzinfo=eastern))

    def test_authored_context_only_returns_actionable_work(self):
        self.assertEqual(
            sync.authored_context(pr(reviewDecision="CHANGES_REQUESTED")),
            ("github-fixup", "changes requested"),
        )
        self.assertEqual(
            sync.authored_context(pr(statusCheckRollup={"state": "FAILURE"})),
            ("github-fixup", "failing CI"),
        )
        self.assertEqual(
            sync.authored_context(pr(reviewDecision="APPROVED")),
            ("github-merge", "approved and ready"),
        )
        self.assertEqual(sync.authored_context(pr(isDraft=True)), (None, None))
        self.assertEqual(sync.authored_context(pr()), (None, None))

    def test_direct_and_team_review_requests_get_distinct_sla_actions(self):
        direct = pr(
            reviewRequests={"nodes": [{"requestedReviewer": {"id": "USER_1", "login": "me"}}]},
            timelineItems={
                "nodes": [
                    {
                        "createdAt": "2026-08-28T19:00:00Z",
                        "requestedReviewer": {"id": "USER_1", "login": "me"},
                    }
                ]
            },
        )
        team = pr(
            id="PR_node_2",
            number=124,
            reviewRequests={
                "nodes": [
                    {
                        "requestedReviewer": {
                            "id": "TEAM_1",
                            "slug": "reviewers",
                            "organization": {"login": "acme"},
                        }
                    }
                ]
            },
            timelineItems={
                "nodes": [
                    {
                        "createdAt": "2026-08-31T13:00:00Z",
                        "requestedReviewer": {
                            "id": "TEAM_1",
                            "slug": "reviewers",
                            "organization": {"login": "acme"},
                        },
                    }
                ]
            },
        )
        payload = {"viewer": "me", "viewerTeamIds": ["TEAM_1"], "requested": [direct, team], "authored": []}
        actions = sync.build_actions(payload, sync.default_state(), local_timezone=timezone.utc)
        self.assertEqual(len(actions), 2)
        due_dates = sorted(action["due_datetime"] for action in actions.values())
        self.assertEqual(due_dates, ["2026-08-31T19:00:00Z", "2026-09-01T13:00:00Z"])

    def test_draft_review_request_is_excluded(self):
        requested = pr(isDraft=True)
        payload = {"viewer": "me", "viewerTeamIds": [], "requested": [requested], "authored": []}
        self.assertEqual(sync.build_actions(payload, sync.default_state()), {})

    def test_authored_pr_without_review_becomes_stale_after_sla(self):
        authored = pr(reviews={"totalCount": 0})
        payload = {"viewer": "me", "requested": [], "authored": [authored]}
        actions = sync.build_actions(
            payload,
            sync.default_state(),
            local_timezone=timezone.utc,
            now=datetime(2026, 8, 28, 19, tzinfo=timezone.utc),
        )
        action = next(iter(actions.values()))
        self.assertEqual(action["context"], "github-stale")
        self.assertEqual(action["due_datetime"], "2026-08-28T19:00:00Z")

    def test_authored_pr_is_not_stale_before_sla_or_after_a_review(self):
        payload = {"viewer": "me", "requested": [], "authored": [pr(reviews={"totalCount": 0})]}
        actions = sync.build_actions(
            payload,
            sync.default_state(),
            local_timezone=timezone.utc,
            now=datetime(2026, 8, 28, 18, 59, tzinfo=timezone.utc),
        )
        self.assertEqual(actions, {})
        payload["authored"][0]["reviews"] = {"totalCount": 1}
        actions = sync.build_actions(
            payload,
            sync.default_state(),
            local_timezone=timezone.utc,
            now=datetime(2026, 8, 31, 19, tzinfo=timezone.utc),
        )
        self.assertEqual(actions, {})

    def test_missing_review_request_event_fails_instead_of_using_mutable_update_time(self):
        requested = pr(
            reviewRequests={"nodes": [{"requestedReviewer": {"id": "USER_1", "login": "me"}}]},
        )
        payload = {"viewer": "me", "viewerTeamIds": [], "requested": [requested], "authored": []}
        with self.assertRaisesRegex(ValueError, "has no timestamp"):
            sync.build_actions(payload, sync.default_state())

    def test_authored_context_gets_a_new_episode_after_resolving(self):
        state = sync.default_state()
        actionable = pr(reviewDecision="CHANGES_REQUESTED")
        payload = {"viewer": "me", "requested": [], "authored": [actionable]}
        first = sync.build_actions(payload, state)
        second = sync.build_actions(payload, state)
        sync.build_actions({"viewer": "me", "requested": [], "authored": []}, state)
        third = sync.build_actions(payload, state)
        self.assertEqual(set(first), set(second))
        self.assertNotEqual(set(first), set(third))

    def test_completed_tasks_restore_episode_state_after_local_state_loss(self):
        state = sync.default_state()
        marker = "github-gtd:v1:PR_node_1:fixup:4"
        sync.hydrate_state_from_tasks(state, [], [{"description": f"GTD Sync: {marker}"}])
        actions = sync.build_actions(
            {"viewer": "me", "requested": [], "authored": [pr(reviewDecision="CHANGES_REQUESTED")]},
            state,
        )
        self.assertEqual(set(actions), {marker})

    def test_reconciliation_preserves_manual_fields_and_repairs_owned_labels(self):
        action_id = "github-gtd:v1:PR_node_1:fixup:1"
        actions = {
            action_id: {
                "id": action_id,
                "content": "generated title",
                "description": "generated description",
                "context": "github-fixup",
                "due_datetime": None,
            }
        }
        active = [
            {
                "id": "todoist-1",
                "content": "My edited title",
                "project_id": "manually-moved",
                "priority": 4,
                "labels": ["deep-work", "needs-review"],
                "description": f"Notes\nGTD Sync: {action_id}",
            }
        ]
        operations = sync.plan_reconciliation(actions, active, [], sync.default_state())
        self.assertEqual(
            operations,
            [
                {
                    "operation": "update-labels",
                    "task_id": "todoist-1",
                    "action_id": action_id,
                    "labels": ["deep-work", "github", "github-fixup"],
                }
            ],
        )

    def test_completed_action_is_not_recreated(self):
        action_id = "github-gtd:v1:PR_node_1:needs-review:2026-08-28T19:00:00Z"
        actions = {
            action_id: {
                "id": action_id,
                "content": "Review acme/app#123",
                "description": "",
                "context": "github-review",
                "due_datetime": None,
            }
        }
        completed = [{"id": "done", "description": f"GTD Sync: {action_id}"}]
        state = sync.default_state()
        operations = sync.plan_reconciliation(actions, [], completed, state)
        self.assertEqual(operations, [])
        self.assertIn(action_id, state["acknowledged"])

    def test_resolved_action_is_completed_without_touching_manual_tasks(self):
        action_id = "github-gtd:v1:PR_node_1:fixup:1"
        active = [
            {"id": "managed", "description": f"GTD Sync: {action_id}", "labels": ["github", "fixup"]},
            {"id": "manual", "description": "", "labels": ["github", "fixup"]},
        ]
        operations = sync.plan_reconciliation({}, active, [], sync.default_state())
        self.assertEqual(
            operations,
            [{"operation": "close", "task_id": "managed", "action_id": action_id}],
        )

    def test_todoist_cursor_pages_accept_v1_result_shapes(self):
        client = sync.TodoistClient("token")
        responses = [
            {"results": [{"id": "one"}], "next_cursor": "next"},
            {"items": [{"id": "two"}], "next_cursor": None},
        ]
        queries = []

        def request(method, path, body=None, query=None):
            queries.append(query)
            return responses.pop(0)

        client.request = request
        self.assertEqual(client.paginated("/tasks"), [{"id": "one"}, {"id": "two"}])
        self.assertNotIn("cursor", queries[0])
        self.assertEqual(queries[1]["cursor"], "next")


if __name__ == "__main__":
    unittest.main()
