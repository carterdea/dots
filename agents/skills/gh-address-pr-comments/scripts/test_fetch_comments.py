"""Offline GitHub transport fixtures for thread fetching and approval gates."""

import unittest
from unittest.mock import patch

import fetch_comments as fetch


def page(nodes, cursor=None):
    return {"nodes": nodes, "pageInfo": {"hasNextPage": cursor is not None, "endCursor": cursor}}


def comment(identifier, state="COMMENTED"):
    return {"id": identifier, "body": identifier, "pullRequestReview": {"state": state}}


class FetchTests(unittest.TestCase):
    def test_resolved_bodies_never_requested_and_outdated_retained(self):
        metadata = {"data": {"repository": {"pullRequest": {
            "number": 1, "url": "https://github.com/a/b/pull/1", "title": "PR",
            "state": "OPEN", "headRefOid": "head",
        }}}}
        threads = [
            {"id": "resolved", "isResolved": True},
            {"id": "outdated", "isResolved": False, "isOutdated": True},
        ]
        body = {"data": {"node": {"isResolved": False, "comments": page([comment("live")])}}}
        with (
            patch.object(fetch, "gh_graphql", return_value=metadata),
            patch.object(fetch, "fetch_connection", side_effect=[[], [{"state": "PENDING", "body": "draft"}], threads]),
            patch.object(fetch, "gh_thread_comments", return_value=body) as request,
            patch.object(fetch, "fetch_pr_reactions", return_value=[]),
        ):
            result = fetch.fetch_all("a", "b", 1)
        request.assert_called_once_with("outdated", None)
        self.assertEqual([t["id"] for t in result["review_threads"]], ["outdated"])
        self.assertEqual(result["reviews"], [])
        self.assertEqual(result["pending_review_count"], 1)
        self.assertNotIn("comments(", fetch.THREADS_QUERY)

    def test_thread_pagination_and_pending_comments(self):
        thread = {"id": "thread", "isResolved": False}
        responses = [
            {"data": {"node": {"isResolved": False, "comments": page([comment("one"), comment("draft", "PENDING")], "next")}}},
            {"data": {"node": {"isResolved": False, "comments": page([comment("two")])}}},
        ]
        with patch.object(fetch, "gh_thread_comments", side_effect=responses) as request:
            fetch.fetch_all_thread_comments(thread)
        self.assertEqual([c["id"] for c in thread["comments"]["nodes"]], ["one", "two"])
        self.assertEqual(request.call_args_list[1].args, ("thread", "next"))

    def test_resolution_during_pagination_discards_partial_body(self):
        thread = {"id": "thread", "isResolved": False}
        responses = [
            {"data": {"node": {"isResolved": False, "comments": page([comment("one")], "next")}}},
            {"data": {"node": {"isResolved": True}}},
        ]
        with patch.object(fetch, "gh_thread_comments", side_effect=responses):
            fetch.fetch_all_thread_comments(thread)
        self.assertTrue(thread["isResolved"])
        self.assertEqual(thread["comments"]["nodes"], [])

    def test_connection_pagination(self):
        responses = [{"data": {"repository": {"pullRequest": {"reviewThreads": connection}}}}
                     for connection in [page([{"id": "one"}], "next"), page([{"id": "two"}])]]
        with patch.object(fetch, "gh_graphql", side_effect=responses):
            result = fetch.fetch_connection("a", "b", 1, fetch.THREADS_QUERY, "reviewThreads")
        self.assertEqual(result, [{"id": "one"}, {"id": "two"}])

    def test_approval_requires_known_bot_current_head_and_latest_review(self):
        review = {"state": "APPROVED", "submittedAt": "2026-09-05T01:00:00Z",
                  "commit": {"oid": "head"},
                  "author": {"login": "chatgpt-codex-connector", "__typename": "Bot"}}
        for head, author, expected in [
            ("head", review["author"], True), ("other", review["author"], False),
            (None, review["author"], False),
            ("head", {"login": "fake-codex", "__typename": "Bot"}, False),
            ("head", {"login": "chatgpt-codex-connector", "__typename": "User"}, False),
        ]:
            with self.subTest(head=head, author=author):
                result = fetch.summarize_approval([], [{**review, "author": author}], head, [], [])
                self.assertEqual(result["has_agent_approval"], expected)
        newer = {**review, "state": "CHANGES_REQUESTED", "submittedAt": "2026-09-05T02:00:00Z"}
        self.assertFalse(fetch.summarize_approval([], [review, newer], "head", [], [])["has_agent_approval"])

    def test_codex_pr_thumbs_up_counts_despite_rest_user_type(self):
        reaction = {"content": "+1", "user": {"login": "chatgpt-codex-connector[bot]", "type": "User"}}
        self.assertTrue(fetch.summarize_approval([reaction], [], "head", [], [])["has_codex_like_thumbs_up"])
        human = {"content": "+1", "user": {"login": "codex-fan", "type": "User"}}
        self.assertFalse(fetch.summarize_approval([human], [], "head", [], [])["has_codex_like_thumbs_up"])

    def test_codex_head_signoff_pairs_thumbs_up_with_summary_commit(self):
        head = "a26c59aa50cbde77e5f3a51d8174f5290ef5fc9b"
        completed = ('| 📝 **Code Review** | ✅ **Completed** <relative-time datetime="2026-09-29T05:16:14.399619Z">'
                     "2026-09-29T05:16:14.399619Z</relative-time> | `a26c59a` | Manual request |")
        running = "| 🔒 **Security Review** | ⏳ **In progress** | `a26c59a` | Manual request |"
        bot = {"login": "chatgpt-codex-connector", "__typename": "Bot"}

        def summary(*rows, author=bot):
            table = "| Review | Status | Commit | Review trigger |\n| --- | --- | --- | --- |\n" + "\n".join(rows)
            return {"id": "summary", "author": author, "updatedAt": "2026-09-29T05:16:15Z",
                    "body": f"{fetch.CODEX_SUMMARY_MARKER}\n\n## Codex Review Summary\n\n{table}\n"}

        def thumbs(at="2026-09-29T05:16:17Z"):
            return [{"content": "+1", "created_at": at, "user": {"login": "chatgpt-codex-connector[bot]", "type": "User"}}]

        for name, reactions, comments, pr_head, expected in [
            ("signed off", thumbs(), [summary(completed)], head, True),
            ("same second as completion", thumbs("2026-09-29T05:16:14Z"), [summary(completed)], head, True),
            ("head moved", thumbs(), [summary(completed)], "b" * 40, False),
            ("review still running", thumbs(), [summary(completed, running)], head, False),
            ("thumbs up predates review", thumbs("2026-09-29T04:00:00Z"), [summary(completed)], head, False),
            ("no thumbs up", [], [summary(completed)], head, False),
            ("no summary", thumbs(), [], head, False),
            ("summary from non-bot", thumbs(), [summary(completed, author={**bot, "__typename": "User"})], head, False),
        ]:
            with self.subTest(name):
                result = fetch.summarize_approval(reactions, [], pr_head, [], comments)
                self.assertIs(result["has_codex_head_signoff"], expected)

        codex = fetch.summarize_approval(thumbs(), [], head, [], [summary(completed)])["codex_review"]
        self.assertEqual(codex["latest_completed"]["commit"], "a26c59a")
        # The summary comment is status, not feedback, so it must not reset the approval clock.
        self.assertIsNone(fetch.summarize_approval([], [], head, [], [summary(completed)])["latest_active_feedback_at"])

    def test_graphql_errors_fail_instead_of_reporting_clean(self):
        with (
            patch.object(fetch, "gh_thread_comments", return_value={"errors": [{"message": "denied"}]}),
            self.assertRaisesRegex(RuntimeError, "denied"),
        ):
            fetch.fetch_all_thread_comments({"id": "thread"})


if __name__ == "__main__":
    unittest.main()
