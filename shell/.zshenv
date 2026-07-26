typeset -U path
path=(
  /opt/homebrew/bin
  /opt/homebrew/sbin
  "$HOME/.bun/bin"
  $path
)
export PATH

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Serialize heavy lefthook pre-push checks machine-wide (see ~/.local/bin/lefthook-ci-lock)
export LEFTHOOK_BIN="$HOME/.local/bin/lefthook-ci-lock"
