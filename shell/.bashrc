# Aliases
alias python='python3'
alias pip='python -m pip'

# PATH configuration
export PATH="$HOME/.local/bin:$PATH"

# Rust (Cargo)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# asdf version manager
. $(brew --prefix asdf)/libexec/asdf.sh
