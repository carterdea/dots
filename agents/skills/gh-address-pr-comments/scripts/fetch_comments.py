#!/usr/bin/env python3
"""Fetch PR comments, reviews, review threads, and approval reactions via gh."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from typing import Any

QUERY = """\
query(
  $owner: String!,
  $repo: String!,
  $number: Int!,
  $commentsCursor: String,
  $reviewsCursor: String,
  $threadsCursor: String
) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      number
      url
      title
      state
      comments(first: 100, after: $commentsCursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          body
          createdAt
          updatedAt
          author { login }
        }
      }
      reviews(first: 100, after: $reviewsCursor) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          state
          body
          submittedAt
          author { login }
        }
      }
      reviewThreads(first: 100, after: $threadsCursor) {
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
          resolvedBy { login }
          comments(first: 100) {
            nodes {
              id
              body
              createdAt
              updatedAt
              author { login }
            }
          }
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


def run_json_list(cmd: list[str], stdin: str | None = None) -> list[dict[str, Any]]:
    out = run(cmd, stdin=stdin)
    try:
        data = json.loads(out)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Failed to parse JSON: {exc}\nRaw:\n{out}") from exc
    if not isinstance(data, list):
        raise RuntimeError(f"Expected JSON list from command: {' '.join(cmd)}")
    return data


def ensure_gh_authenticated() -> None:
    try:
        run(["gh", "auth", "status"])
    except RuntimeError as exc:
        print("Run `gh auth login` to authenticate the GitHub CLI.", file=sys.stderr)
        raise SystemExit(1) from exc


def resolve_repo() -> tuple[str, str]:
    repo = run_json(["gh", "repo", "view", "--json", "owner,name"])
    return repo["owner"]["login"], repo["name"]


def resolve_current_pr() -> tuple[str, str, int]:
    pr = run_json(["gh", "pr", "view", "--json", "number,headRepositoryOwner,headRepository"])
    return pr["headRepositoryOwner"]["login"], pr["headRepository"]["name"], int(pr["number"])


def parse_repo(value: str) -> tuple[str, str]:
    if "/" not in value:
        raise SystemExit("--repo must be OWNER/REPO")
    owner, repo = value.split("/", 1)
    return owner, repo


def gh_graphql(
    owner: str,
    repo: str,
    number: int,
    comments_cursor: str | None = None,
    reviews_cursor: str | None = None,
    threads_cursor: str | None = None,
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
    if comments_cursor:
        cmd += ["-F", f"commentsCursor={comments_cursor}"]
    if reviews_cursor:
        cmd += ["-F", f"reviewsCursor={reviews_cursor}"]
    if threads_cursor:
        cmd += ["-F", f"threadsCursor={threads_cursor}"]
    return run_json(cmd, stdin=QUERY)


def fetch_pr_reactions(owner: str, repo: str, number: int) -> list[dict[str, Any]]:
    return run_json_list(
        [
            "gh",
            "api",
            "-H",
            "Accept: application/vnd.github+json",
            f"repos/{owner}/{repo}/issues/{number}/reactions?per_page=100",
        ]
    )


def summarize_approval(reactions: list[dict[str, Any]]) -> dict[str, Any]:
    thumbs_up = [reaction for reaction in reactions if reaction.get("content") == "+1"]
    codex_like = []
    for reaction in thumbs_up:
        user = reaction.get("user") or {}
        login = (user.get("login") or "").lower()
        user_type = (user.get("type") or "").lower()
        if "codex" in login or "openai" in login or user_type == "bot":
            codex_like.append(reaction)
    return {
        "has_thumbs_up": bool(thumbs_up),
        "has_codex_like_thumbs_up": bool(codex_like),
        "thumbs_up_count": len(thumbs_up),
        "thumbs_up_authors": [
            (reaction.get("user") or {}).get("login")
            for reaction in thumbs_up
            if (reaction.get("user") or {}).get("login")
        ],
    }


def fetch_all(owner: str, repo: str, number: int) -> dict[str, Any]:
    conversation_comments: list[dict[str, Any]] = []
    reviews: list[dict[str, Any]] = []
    review_threads: list[dict[str, Any]] = []
    comments_cursor: str | None = None
    reviews_cursor: str | None = None
    threads_cursor: str | None = None
    pr_meta: dict[str, Any] | None = None

    while True:
        payload = gh_graphql(owner, repo, number, comments_cursor, reviews_cursor, threads_cursor)
        if payload.get("errors"):
            raise RuntimeError(json.dumps(payload["errors"], indent=2))

        pr = payload["data"]["repository"]["pullRequest"]
        if pr_meta is None:
            pr_meta = {
                "number": pr["number"],
                "url": pr["url"],
                "title": pr["title"],
                "state": pr["state"],
                "owner": owner,
                "repo": repo,
            }

        comments = pr["comments"]
        review_page = pr["reviews"]
        threads = pr["reviewThreads"]
        conversation_comments.extend(comments.get("nodes") or [])
        reviews.extend(review_page.get("nodes") or [])
        review_threads.extend(threads.get("nodes") or [])

        comments_cursor = comments["pageInfo"]["endCursor"] if comments["pageInfo"]["hasNextPage"] else None
        reviews_cursor = review_page["pageInfo"]["endCursor"] if review_page["pageInfo"]["hasNextPage"] else None
        threads_cursor = threads["pageInfo"]["endCursor"] if threads["pageInfo"]["hasNextPage"] else None
        if not (comments_cursor or reviews_cursor or threads_cursor):
            break

    reactions = fetch_pr_reactions(owner, repo, number)

    return {
        "pull_request": pr_meta,
        "conversation_comments": conversation_comments,
        "reviews": reviews,
        "review_threads": review_threads,
        "pr_reactions": reactions,
        "approval": summarize_approval(reactions),
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
        number = args.pr
    elif args.pr is not None:
        owner, repo = resolve_repo()
        number = args.pr
    else:
        owner, repo, number = resolve_current_pr()

    print(json.dumps(fetch_all(owner, repo, number), indent=2))


if __name__ == "__main__":
    main()
