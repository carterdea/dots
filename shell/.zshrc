# oh-my-zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

# Plugins
plugins=(git docker colorize)

source $ZSH/oh-my-zsh.sh

# Initialize zoxide (modern directory jumper)
eval "$(zoxide init zsh)"

# History configuration
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY

# Editor
export EDITOR="cursor -w"

# Environment variables
export SHOPIFY_CLI_STACKTRACE=1
export NVM_DIR="$HOME/.nvm"

# PATH configuration
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
export PATH="$HOME/.bun/bin:$PATH"
export PATH="$HOME/.rvm/bin:$PATH"

# Aliases
alias sublime="subl"
alias fs="foreman start -f Procfile.dev"
alias python='python3'
alias pip='python -m pip'

# Modern CLI tool aliases
alias cat='bat'
alias grep='rg'
alias find='fd'

# NVM
[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && \. "$(brew --prefix)/opt/nvm/nvm.sh"
[ -s "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$(brew --prefix)/opt/nvm/etc/bash_completion.d/nvm"

# Rust (Cargo)
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Docker CLI completions
fpath=($HOME/.docker/completions $fpath)
autoload -Uz compinit
compinit
