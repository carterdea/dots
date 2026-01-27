# Load .bashrc if it exists
[[ -f "$HOME/.bashrc" ]] && source "$HOME/.bashrc"

# asdf version manager
. $(brew --prefix asdf)/libexec/asdf.sh
