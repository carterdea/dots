#!/usr/bin/env bash
# Custom status line for Claude Code
# Claude Code pipes JSON data to this script via stdin
# The script outputs text to display in the status line

# Read JSON from stdin
input=$(cat)

# Parse JSON using jq if available, otherwise use basic parsing
if command -v jq &> /dev/null; then
  # Extract useful info from JSON
  model=$(echo "$input" | jq -r '.model // "unknown"')
  tokens=$(echo "$input" | jq -r '.tokens.used // 0')
  tokens_max=$(echo "$input" | jq -r '.tokens.max // 200000')
  cost=$(echo "$input" | jq -r '.cost.total // 0')

  # Calculate token percentage
  if [ "$tokens_max" -gt 0 ]; then
    percent=$((tokens * 100 / tokens_max))
  else
    percent=0
  fi

  # Get git branch if in a repo
  branch=""
  if git rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    branch=" | $branch"
  fi

  # Output status line
  echo "$model | ${percent}% (${tokens}/${tokens_max}) | \$${cost}${branch}"
else
  # Fallback if jq is not available - just show git branch
  if git rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    echo "git: $branch"
  else
    echo "claude-code"
  fi
fi
