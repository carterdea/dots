typeset -U path
path=(
  /opt/homebrew/bin
  /opt/homebrew/sbin
  "$HOME/.bun/bin"
  $path
)
export PATH

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Serialize heavy lefthook pre-push checks machine-wide.
# Only once the shim exists: these dotfiles are symlinked, so a pull can land
# this line before install.sh has created it, and lefthook fails every push
# when LEFTHOOK_BIN points at something missing.
if [ -x "$HOME/.local/bin/lefthook-ci-lock" ]; then
  export LEFTHOOK_BIN="$HOME/.local/bin/lefthook-ci-lock"
fi
