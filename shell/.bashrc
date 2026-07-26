# Aliases
alias python='python3'
alias pip='python -m pip'

# PATH configuration
export PATH="$HOME/.local/bin:$PATH"

# Serialize heavy lefthook pre-push checks machine-wide (mirrors .zshenv)
export LEFTHOOK_BIN="$HOME/.local/bin/lefthook-ci-lock"

# Rust (Cargo)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# asdf version manager
. $(brew --prefix asdf)/libexec/asdf.sh

# dcg: warn if hook was silently removed from Claude Code settings
if command -v dcg &>/dev/null && command -v jq &>/dev/null; then
  if [ -f "$HOME/.claude/settings.json" ] &&
    ! jq -e '.hooks.PreToolUse[]? | select(.hooks[]?.command | test("dcg$"))' \
      "$HOME/.claude/settings.json" &>/dev/null; then
    printf '\033[1;33m[dcg] Hook missing from ~/.claude/settings.json — run: dcg install\033[0m\n'
  fi
fi
