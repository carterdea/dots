#!/usr/bin/env bash
# SessionStart hook: prepare fresh Claude Code git worktrees without touching
# the main checkout. Important projects reuse their reviewed Codex environment
# recipe; other repositories get the conservative lockfile-only fallback.
set -uo pipefail

WT="$(git -C "${CLAUDE_PROJECT_DIR:-$PWD}" rev-parse --show-toplevel 2>/dev/null)" || exit 0
[ -n "$WT" ] || exit 0

common_git_dir="$(git -C "$WT" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || exit 0
worktree_git_dir="$(git -C "$WT" rev-parse --path-format=absolute --git-dir 2>/dev/null)" || exit 0
MAIN="$(dirname "$common_git_dir")"

# The primary checkout has the common git directory as its own git directory.
[ "$worktree_git_dir" = "$common_git_dir" ] && exit 0

# Avoid mistaking a submodule for a linked worktree.
git -C "$MAIN" worktree list --porcelain 2>/dev/null \
  | awk '/^worktree / { sub(/^worktree /, ""); print }' \
  | grep -Fxq "$WT" || exit 0

project_name="$(basename "$MAIN")"
case "$project_name" in
  service-ops-ai-app|mmops|rawna-web|rawna-mobile|rezio-app|bob-aka-katie-sim|sale-sight|ellesse-us-shopify|ghost-spider-game|modern-matter|otw-rewrite|peptiva|neweracap-shopify)
    codex_config="$MAIN/.codex/environments/environment.toml"
    ;;
  *)
    codex_config=""
    ;;
esac

environment_is_complete() {
  local relative_path source_file

  [ ! -f "$WT/package.json" ] || [ -d "$WT/node_modules" ] || return 1
  [ ! -f "$WT/pyproject.toml" ] || [ -d "$WT/.venv" ] || return 1

  for relative_path in apps/web apps/mobile rawna-mobile; do
    [ ! -f "$WT/$relative_path/package.json" ] || [ -d "$WT/$relative_path/node_modules" ] || return 1
  done

  if [ -f "$MAIN/.worktreeinclude" ]; then
    while IFS= read -r relative_path; do
      case "$relative_path" in
        ""|'#'*|'!'*|*'*'*|*'?'*|*'['*) continue ;;
      esac
      source_file="$MAIN/$relative_path"
      [ ! -f "$source_file" ] || [ -e "$WT/$relative_path" ] || return 1
    done < "$MAIN/.worktreeinclude"
  fi
}

run_codex_environment() {
  local digest lock_file log_file marker setup_script
  local -a digest_inputs

  [ -f "$codex_config" ] || return 1
  digest_inputs=("$codex_config")
  for lock_file in bun.lock uv.lock pnpm-lock.yaml apps/web/bun.lock apps/mobile/bun.lock rawna-mobile/bun.lock; do
    [ ! -f "$WT/$lock_file" ] || digest_inputs+=("$WT/$lock_file")
  done
  digest="$(
    printf '%s\n' 'claude-worktree-bootstrap-v2'
    git hash-object "${digest_inputs[@]}"
  )"
  digest="$(printf '%s\n' "$digest" | git hash-object --stdin)"
  marker="$worktree_git_dir/claude-worktree-bootstrap.sha256"

  if [ -f "$marker" ] && [ "$(<"$marker")" = "$digest" ] && environment_is_complete; then
    return 0
  fi

  setup_script="$(sed -n "/^script = '''$/,/^'''$/p" "$codex_config" | sed '1d;$d')"
  [ -n "$setup_script" ] || return 1

  log_file="$(mktemp "${TMPDIR:-/tmp}/worktree-bootstrap.log.XXXXXX")"
  echo "worktree-bootstrap: preparing $project_name..." >&2
  if MAIN_REPO="$MAIN" WORKTREE="$WT" bash -euo pipefail -c "$setup_script" >"$log_file" 2>&1; then
    printf '%s\n' "$digest" > "$marker"
    rm -f "$log_file"
    echo "worktree-bootstrap: $project_name ready" >&2
    return 0
  fi

  echo "worktree-bootstrap: setup failed; log: $log_file (session continuing)" >&2
  tail -n 80 "$log_file" >&2
  return 1
}

if [ -n "$codex_config" ]; then
  run_codex_environment || true
  exit 0
fi

# Conservative fallback for projects without an explicit environment recipe.
linked=0
while IFS= read -r relative_path; do
  [ -n "$relative_path" ] || continue
  source_file="$MAIN/$relative_path"
  destination="$WT/$relative_path"
  [ -f "$source_file" ] || continue
  [ -e "$destination" ] && continue
  git -C "$WT" check-ignore -q -- "$relative_path" 2>/dev/null || continue
  mkdir -p "$(dirname "$destination")"
  ln -s "$source_file" "$destination" && linked=$((linked + 1))
done < <(
  git -C "$MAIN" ls-files -o -i --exclude-standard -z -- ':(glob)**/.env*' 2>/dev/null \
    | tr '\0' '\n' \
    | grep -E '(^|/)\.env([.][^/]*)?$' \
    | grep -vE '(^|/)(node_modules|\.claude|\.worktrees|\.trapper_keeper)/' \
    | grep -vE '(^|/)\.env(\.|$).*(prod|production)' \
    | grep -vE '\.(example|prod|production)(\.|$)'
)
[ "$linked" -eq 0 ] || echo "worktree-bootstrap: linked $linked env file(s) from $MAIN" >&2

if [ -f "$WT/package.json" ] && [ ! -d "$WT/node_modules" ] && [ ! -f "$WT/.pnp.cjs" ] \
  && [ ! -f "$WT/.pnp.loader.mjs" ] && [ ! -f "$WT/.yarn/install-state.gz" ]; then
  if [ -f "$WT/bun.lock" ] || [ -f "$WT/bun.lockb" ]; then install=(bun install --frozen-lockfile --ignore-scripts)
  elif [ -f "$WT/pnpm-lock.yaml" ]; then install=(pnpm install --frozen-lockfile --ignore-scripts)
  elif [ -f "$WT/yarn.lock" ] \
    && { grep -Eq '"?packageManager"?[[:space:]]*:[[:space:]]*"?yarn@([2-9]|[1-9][0-9])' "$WT/package.json" 2>/dev/null || [ -f "$WT/.yarnrc.yml" ]; }; then
    install=(env YARN_ENABLE_SCRIPTS=false yarn install --immutable)
  elif [ -f "$WT/yarn.lock" ]; then install=(yarn install --frozen-lockfile --ignore-scripts)
  elif [ -f "$WT/package-lock.json" ]; then install=(npm ci --ignore-scripts)
  else echo "worktree-bootstrap: skipping dep install (no supported lockfile)" >&2; exit 0; fi

  log_file="$(mktemp "${TMPDIR:-/tmp}/worktree-bootstrap.log.XXXXXX")"
  echo "worktree-bootstrap: installing dependencies..." >&2
  if (cd "$WT" && "${install[@]}") >"$log_file" 2>&1; then
    rm -f "$log_file"
    echo "worktree-bootstrap: dependencies ready" >&2
  else
    echo "worktree-bootstrap: install failed; log: $log_file (session continuing)" >&2
  fi
fi

exit 0
