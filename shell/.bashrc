# Aliases
alias python='python3'
alias pip='python -m pip'

# PATH configuration
export PATH="$HOME/.local/bin:$PATH"

# Serialize heavy lefthook pre-push checks machine-wide (mirrors .zshenv).
# Guarded because a pull can land this before install.sh creates the shim.
if [ -x "$HOME/.local/bin/lefthook-ci-lock" ]; then
  export LEFTHOOK_BIN="$HOME/.local/bin/lefthook-ci-lock"
fi

# Rust (Cargo)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# asdf version manager
. $(brew --prefix asdf)/libexec/asdf.sh
