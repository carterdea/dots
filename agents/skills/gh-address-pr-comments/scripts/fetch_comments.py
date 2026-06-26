#!/usr/bin/env python3
"""Fetch PR comments, reviews, review threads, and approval reactions via gh."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from typing import Any

META_QUERY = """\
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      number
      url
      title
      state
      headRefOid
    }
  }
}
"""

COMMENTS_QUERY = """\
query($owner: String!, $repo: String!, $number: Int!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      comments(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          body
          createdAt
          updatedAt
          author { __typename login }
        }
      }
    }
  }
}
"""

REVIEWS_QUERY = """\
query($owner: String!, $repo: String!, $number: Int!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviews(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          state
          body
          submittedAt
          commit { oid }
          author { __typename login }
        }
      }
    }
  }
}
"""

THREADS_QUERY = """\
query($owner: String!, $repo: String!, $number: Int!, $cursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          isOutdated
          path
          line
          diffSide
          startLine
          startDiffSide
          originalLine
          originalStartLine
          resolvedBy { __typename login }
          comments(first: 100) {
            pageInfo { hasNextPage endCursor }
            nodes {
              id
              body
              createdAt
              updatedAt
              author { __typename login }
            }
          }
        }
      }
    }
  }
}
"""

THREAD_COMMENTS_QUERY = """\
query($threadId: ID!, $cursor: String) {
  node(id: $threadId) {
    ... on PullRequestReviewThread {
      comments(first: 100, after: $cursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          body
          createdAt
          updatedAt
          author { __typename login }
        }
      }
    }
  }
}
"""


def run(cmd: list[str], stdin: str | None = None) -> str:
    result = subprocess.run(cmd, input=stdin, capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd)}\n{result.stderr}")
    return result.stdout


def run_json(cmd: list[str], stdin: str | None = None) -> dict[str, Any]:
    out = run(cmd, stdin=stdin)
    try:
        return json.loads(out)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Failed to parse JSON: {exc}\nRaw:\n{out}") from exc


def run_json_value(cmd: list[str], stdin: str | None = None) -> Any:
    out = run(cmd, stdin=stdin)
    try:
        return json.loads(out)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Failed to parse JSON: {exc}\nRaw:\n{out}") from exc


def run_json_list(cmd: list[str], stdin: str | None = None) -> list[dict[str, Any]]:
    data = run_json_value(cmd, stdin=stdin)
    if not isinstance(data, list):
        raise RuntimeError(f"Expected JSON list from command: {' '.join(cmd)}")
    if all(isinstance(page, list) for page in data):
        return [item for page in data for item in page]
    return data


def ensure_gh_authenticated() -> None:
    try:
        run(["gh", "auth", "status"])
    except RuntimeError as exc:
        print("Run `gh auth login` to authenticate the GitHub CLI.", file=sys.stderr)
        raise SystemExit(1) from exc


def parse_pr_url(url: str) -> tuple[str, str]:
    marker = "github.com/"
    if marker not in url:
        raise RuntimeError(f"Cannot parse PR URL: {url}")
    path = url.split(marker, 1)[1]
    owner, repo, *_ = path.split("/")
    return owner, repo


def resolve_current_pr() -> tuple[str, str, int]:
    pr = run_json(["gh", "pr", "view", "--json", "number,url"])
    owner, repo = parse_pr_url(pr["url"])
    return owner, repo, int(pr["number"])


def resolve_pr(owner: str, repo: str, number: int) -> tuple[str, str, int]:
    pr = run_json(["gh", "pr", "view", str(number), "--repo", f"{owner}/{repo}", "--json", "number,url"])
    base_owner, base_repo = parse_pr_url(pr["url"])
    return base_owner, base_repo, int(pr["number"])


def parse_repo(value: str) -> tuple[str, str]:
    if "/" not in value:
        raise SystemExit("--repo must be OWNER/REPO")
    owner, repo = value.split("/", 1)
    return owner, repo


def gh_graphql(
    query: str,
    owner: str,
    repo: str,
    number: int,
    cursor: str | None = None,
) -> dict[str, Any]:
    cmd = [
        "gh",
        "api",
        "graphql",
        "-F",
        "query=@-",
        "-F",
        f"owner={owner}",
        "-F",
        f"repo={repo}",
        "-F",
        f"number={number}",
    ]
    if cursor:
        cmd += ["-F", f"cursor={cursor}"]
    return run_json(cmd, stdin=query)


def gh_thread_comments(thread_id: str, cursor: str | None = None) -> dict[str, Any]:
    cmd = ["gh", "api", "graphql", "-F", "query=@-", "-F", f"threadId={thread_id}"]
    if cursor:
        cmd += ["-F", f"cursor={cursor}"]
    return run_json(cmd, stdin=THREAD_COMMENTS_QUERY)


def fetch_connection(owner: str, repo: str, number: int, query: str, key: str) -> list[dict[str, Any]]:
    nodes: list[dict[str, Any]] = []
    cursor: str | None = None
    while True:
        payload = gh_graphql(query, owner, repo, number, cursor)
        if payload.get("errors"):
            raise RuntimeError(json.dumps(payload["errors"], indent=2))
        connection = payload["data"]["repository"]["pullRequest"][key]
        nodes.extend(connection.get("nodes") or [])
        page_info = connection["pageInfo"]
        if not page_info["hasNextPage"]:
            return nodes
        cursor = page_info["endCursor"]


def fetch_all_thread_comments(thread: dict[str, Any]) -> None:
    comments = thread.get("comments") or {}
    page_info = comments.get("pageInfo") or {}
    if not page_info.get("hasNextPage"):
        return

    nodes = list(comments.get("nodes") or [])
    cursor = page_info.get("endCursor")
    while cursor:
        payload = gh_thread_comments(thread["id"], cursor)
        if payload.get("errors"):
            raise RuntimeError(json.dumps(payload["errors"], indent=2))
        connection = payload["data"]["node"]["comments"]
        nodes.extend(connection.get("nodes") or [])
        page_info = connection["pageInfo"]
        cursor = page_info["endCursor"] if page_info["hasNextPage"] else None
    thread["comments"] = {"nodes": nodes}


def fetch_pr_reactions(owner: str, repo: str, number: int) -> list[dict[str, Any]]:
    return run_json_list(
        [
            "gh",
            "api",
            "-H",
            "Accept: application/vnd.github+json",
            "--paginate",
            "--slurp",
            f"repos/{owner}/{repo}/issues/{number}/reactions?per_page=100",
        ]
    )


def is_review_agent(author: dict[str, Any] | None) -> bool:
    if not author:
        return False
    login = (author.get("login") or "").lower()
    typename = (author.get("__typename") or "").lower()
    if typename not in {"bot", "app"}:
        return False
    return (
        "codex" in login
        or "openai" in login
        or "chatgpt" in login
        or "claude" in login
        or "anthropic" in login
    )


def summarize_approval(
    reactions: list[dict[str, Any]], reviews: list[dict[str, Any]], head_ref_oid: str | None
) -> dict[str, Any]:
    thumbs_up = [reaction for reaction in reactions if reaction.get("content") == "+1"]
    codex_like = []
    for reaction in thumbs_up:
        user = reaction.get("user") or {}
        login = (user.get("login") or "").lower()
        user_type = (user.get("type") or "").lower()
        if user_type not in {"bot", "app"}:
            continue
        if (
            "codex" in login
            or "openai" in login
            or "chatgpt" in login
            or "claude" in login
            or "anthropic" in login
        ):
            codex_like.append(reaction)

    agent_reviews = [review for review in reviews if is_review_agent(review.get("author"))]
    agent_approvals = [
        review
        for review in agent_reviews
        if review.get("state") == "APPROVED"
        and (not head_ref_oid or (review.get("commit") or {}).get("oid") == head_ref_oid)
    ]
    latest_agent_review = max(agent_reviews, key=lambda review: review.get("submittedAt") or "", default=None)
    latest_agent_review_commit = (latest_agent_review.get("commit") or {}).get("oid") if latest_agent_review else None
    latest_agent_review_matches_head = bool(
        latest_agent_review and (not head_ref_oid or latest_agent_review_commit == head_ref_oid)
    )
    latest_agent_review_approves = bool(
        latest_agent_review
        and latest_agent_review.get("state") == "APPROVED"
        and latest_agent_review_matches_head
    )
    return {
        "has_agent_approval": bool(latest_agent_review_approves or codex_like),
        "has_thumbs_up": bool(codex_like),
        "has_any_thumbs_up": bool(thumbs_up),
        "has_codex_like_thumbs_up": bool(codex_like),
        "has_agent_review_approval": latest_agent_review_approves,
        "thumbs_up_count": len(thumbs_up),
        "thumbs_up_authors": [
            (reaction.get("user") or {}).get("login")
            for reaction in thumbs_up
            if (reaction.get("user") or {}).get("login")
        ],
        "agent_approval_reviews": [
            {
                "id": review.get("id"),
                "state": review.get("state"),
                "submittedAt": review.get("submittedAt"),
                "author": (review.get("author") or {}).get("login"),
                "commitOid": (review.get("commit") or {}).get("oid"),
            }
            for review in agent_approvals
        ],
        "latest_agent_review": {
            "id": latest_agent_review.get("id"),
            "state": latest_agent_review.get("state"),
            "submittedAt": latest_agent_review.get("submittedAt"),
            "author": (latest_agent_review.get("author") or {}).get("login"),
            "commitOid": latest_agent_review_commit,
            "matchesHead": latest_agent_review_matches_head,
        }
        if latest_agent_review
        else None,
    }


def fetch_all(owner: str, repo: str, number: int) -> dict[str, Any]:
    payload = gh_graphql(META_QUERY, owner, repo, number)
    if payload.get("errors"):
        raise RuntimeError(json.dumps(payload["errors"], indent=2))
    pr = payload["data"]["repository"]["pullRequest"]
    pr_meta = {
        "number": pr["number"],
        "url": pr["url"],
        "title": pr["title"],
        "state": pr["state"],
        "headRefOid": pr["headRefOid"],
        "owner": owner,
        "repo": repo,
    }
    conversation_comments = fetch_connection(owner, repo, number, COMMENTS_QUERY, "comments")
    reviews = fetch_connection(owner, repo, number, REVIEWS_QUERY, "reviews")
    review_threads = fetch_connection(owner, repo, number, THREADS_QUERY, "reviewThreads")
    for thread in review_threads:
        fetch_all_thread_comments(thread)
    reactions = fetch_pr_reactions(owner, repo, number)

    return {
        "pull_request": pr_meta,
        "conversation_comments": conversation_comments,
        "reviews": reviews,
        "review_threads": review_threads,
        "pr_reactions": reactions,
        "approval": summarize_approval(reactions, reviews, pr_meta["headRefOid"]),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Fetch PR comments, review thread state, and reactions via gh.")
    parser.add_argument("--repo", help="Repository as OWNER/REPO. Defaults to current gh repo context.")
    parser.add_argument("--pr", type=int, help="Pull request number. Defaults to current branch PR.")
    args = parser.parse_args()

    ensure_gh_authenticated()
    if args.repo:
        owner, repo = parse_repo(args.repo)
        if args.pr is None:
            raise SystemExit("--pr is required when --repo is provided")
        owner, repo, number = resolve_pr(owner, repo, args.pr)
    elif args.pr is not None:
        pr = run_json(["gh", "pr", "view", str(args.pr), "--json", "number,url"])
        owner, repo = parse_pr_url(pr["url"])
        number = int(pr["number"])
    else:
        owner, repo, number = resolve_current_pr()

    print(json.dumps(fetch_all(owner, repo, number), indent=2))


if __name__ == "__main__":
    main()
