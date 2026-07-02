#!/usr/bin/env bash
# SessionStart hook: bootstrap a fresh Claude Code git worktree.
# - Symlinks gitignored dev/test .env files from the MAIN repo into the worktree.
# - Installs dependencies (auto-detects the package manager) if node_modules is missing.
# No-op unless the current session is inside a git worktree, so it is safe to run
# globally on every SessionStart. Never fails the session (always exits 0).
set -uo pipefail

# Normalize to the worktree's own root: launching from a subdirectory of the
# main checkout would otherwise leave WT as the subdir while MAIN resolves to the
# repo root, and the main repo would be misread as a linked worktree.
WT="$(git -C "${CLAUDE_PROJECT_DIR:-$PWD}" rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -n "$WT" ] || exit 0

common_git_dir="$(git -C "$WT" rev-parse --git-common-dir 2>/dev/null)" || exit 0
case "$common_git_dir" in
  /*) : ;;
  *) common_git_dir="$WT/$common_git_dir" ;;
esac
MAIN="$(cd "$(dirname "$common_git_dir")" 2>/dev/null && pwd)" || exit 0

# Only act inside a worktree (main repo needs no bootstrapping).
[ -z "$MAIN" ] && exit 0
[ "$MAIN" = "$WT" ] && exit 0

# A submodule also has a separate git dir under the superproject's .git/modules,
# but it is not a linked worktree. Only bootstrap roots that git worktree lists.
git -C "$MAIN" worktree list --porcelain 2>/dev/null \
  | awk '/^worktree / { sub(/^worktree /, ""); print }' \
  | grep -Fxq "$WT" || exit 0

linked=0
while IFS= read -r rel; do
  [ -n "$rel" ] || continue
  src="$MAIN/$rel"
  dest="$WT/$rel"
  [ -f "$src" ] || continue
  [ -e "$dest" ] && continue
  git -C "$WT" check-ignore -q -- "$rel" 2>/dev/null || continue
  mkdir -p "$(dirname "$dest")"
  ln -s "$src" "$dest" && linked=$((linked + 1))
done < <(
  git -C "$MAIN" ls-files -o -i --exclude-standard -z -- ':(glob)**/.env*' 2>/dev/null \
    | tr '\0' '\n' \
    | grep -E '(^|/)\.env([.][^/]*)?$' \
    | grep -vE '(^|/)(node_modules|\.claude|\.worktrees|\.trapper_keeper)/' \
    | grep -vE '(^|/)\.env(\.|$).*(prod|production)' \
    | grep -vE '\.(example|prod|production)(\.|$)'
)
[ "$linked" -gt 0 ] && echo "worktree-bootstrap: linked $linked env file(s) from $MAIN"

# Install deps only when missing and a JS project is present.
if [ -f "$WT/package.json" ] \
  && [ ! -d "$WT/node_modules" ] \
  && [ ! -f "$WT/.pnp.cjs" ] \
  && [ ! -f "$WT/.pnp.loader.mjs" ] \
  && [ ! -f "$WT/.yarn/install-state.gz" ]; then
  # Lockfile-respecting installs only: without a lockfile, any automatic install
  # can resolve new versions or write a fresh lockfile before the task begins.
  if [ -f "$WT/bun.lock" ] || [ -f "$WT/bun.lockb" ]; then install="bun install --frozen-lockfile --ignore-scripts"
  elif [ -f "$WT/pnpm-lock.yaml" ]; then install="pnpm install --frozen-lockfile --ignore-scripts"
  elif [ -f "$WT/yarn.lock" ] \
    && { grep -Eq '"?packageManager"?[[:space:]]*:[[:space:]]*"?yarn@([2-9]|[1-9][0-9])' "$WT/package.json" 2>/dev/null || [ -f "$WT/.yarnrc.yml" ]; }; then
    install="YARN_ENABLE_SCRIPTS=false yarn install --immutable"
  elif [ -f "$WT/yarn.lock" ]; then install="yarn install --frozen-lockfile --ignore-scripts"
  elif [ -f "$WT/package-lock.json" ]; then install="npm ci --ignore-scripts"
  else echo "worktree-bootstrap: skipping dep install (no lockfile)"; exit 0; fi
  log_file="$(mktemp "${TMPDIR:-/tmp}/worktree-bootstrap.log.XXXXXX")"
  echo "worktree-bootstrap: installing deps ($install)..."
  if (cd "$WT" && eval "$install") >"$log_file" 2>&1; then
    rm -f "$log_file"
    echo "worktree-bootstrap: dep install complete"
  else
    echo "worktree-bootstrap: dep install failed; log: $log_file (continuing)"
  fi
fi

exit 0
