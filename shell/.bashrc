# Aliases
alias python='python3'
alias pip='python -m pip'

# PATH configuration
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.rvm/bin:$PATH"

# Rust (Cargo)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
