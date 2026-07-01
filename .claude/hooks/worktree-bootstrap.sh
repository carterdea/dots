#!/usr/bin/env bash
# SessionStart hook: bootstrap a fresh Claude Code git worktree.
# - Symlinks gitignored dev/test .env files from the MAIN repo into the worktree.
# - Installs dependencies (auto-detects the package manager) if node_modules is missing.
# No-op unless the current session is inside a git worktree, so it is safe to run
# globally on every SessionStart. Never fails the session (always exits 0).
set -uo pipefail

WT="${CLAUDE_PROJECT_DIR:-$PWD}"

common_git_dir="$(git -C "$WT" rev-parse --git-common-dir 2>/dev/null)" || exit 0
case "$common_git_dir" in
  /*) : ;;
  *) common_git_dir="$WT/$common_git_dir" ;;
esac
MAIN="$(cd "$(dirname "$common_git_dir")" 2>/dev/null && pwd)" || exit 0

# Only act inside a worktree (main repo needs no bootstrapping).
[ -z "$MAIN" ] && exit 0
[ "$MAIN" = "$WT" ] && exit 0

linked=0
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  src="$MAIN/$rel"
  dest="$WT/$rel"
  [ -f "$src" ] || continue
  [ -e "$dest" ] && continue
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest" && linked=$((linked + 1))
done < <(
  git -C "$MAIN" ls-files -o -i --exclude-standard -z -- ':(glob)**/.env*' 2>/dev/null \
    | tr '\0' '\n' \
    | grep -E '(^|/)\.env([.][^/]*)?$' \
    | grep -vE '(^|/)(node_modules|\.claude|\.worktrees|\.trapper_keeper)/' \
    | grep -vE '\.(example|production)$'
)
[ "$linked" -gt 0 ] && echo "worktree-bootstrap: linked $linked env file(s) from $MAIN"

# Install deps only when missing and a JS project is present.
if [ -f "$WT/package.json" ] && [ ! -d "$WT/node_modules" ]; then
  if [ -f "$WT/bun.lock" ] || [ -f "$WT/bun.lockb" ]; then install="bun install"
  elif [ -f "$WT/pnpm-lock.yaml" ]; then install="pnpm install"
  elif [ -f "$WT/yarn.lock" ]; then install="yarn install"
  elif [ -f "$WT/package-lock.json" ]; then install="npm install"
  else install="bun install"; fi
  echo "worktree-bootstrap: installing deps ($install)..."
  (cd "$WT" && eval "$install") || echo "worktree-bootstrap: dep install failed (continuing)"
fi

exit 0
