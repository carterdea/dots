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

# asdf version manager
. $(brew --prefix asdf)/libexec/asdf.sh

# Load local configuration (API keys, secrets, machine-specific settings)
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# Pi worktree support
PI_WORKTREE_SH="$HOME/.pi/agent/git/github.com/carterdea/pi-worktrees/shell/pi.zsh"
[ -f "$PI_WORKTREE_SH" ] && source "$PI_WORKTREE_SH"

# dcg: warn if hook was silently removed from Claude Code settings
if command -v dcg &>/dev/null && command -v jq &>/dev/null; then
  if [ -f "$HOME/.claude/settings.json" ] &&
    ! jq -e '.hooks.PreToolUse[]? | select(.hooks[]?.command | test("dcg$"))' \
      "$HOME/.claude/settings.json" &>/dev/null; then
    printf '\033[1;33m[dcg] Hook missing from ~/.claude/settings.json — run: dcg install\033[0m\n'
  fi
fi

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# sentry
fpath=("$HOME/.local/share/zsh/site-functions" $fpath)
