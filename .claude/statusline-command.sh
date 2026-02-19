#!/usr/bin/env bash
# Custom status line for Claude Code
# Claude Code pipes JSON data to this script via stdin
# The script outputs text to display in the status line

# Read JSON from stdin
input=$(cat)

# Parse JSON using jq if available, otherwise use basic parsing
if command -v jq &> /dev/null; then
  model=$(echo "$input" | jq -r '.model.display_name // "?"')
  used=$(echo "$input" | jq -r '.context_window.total_input_tokens // empty')
  max=$(echo "$input" | jq -r '.context_window.context_window_size // empty')
  cost_raw=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
  cost=$([[ -n "$cost_raw" ]] && printf "%.2f" "$cost_raw" || echo "?")

  if [[ -n "$used" && -n "$max" && "$max" -gt 0 ]]; then
    percent=$(awk "BEGIN {printf \"%d\", $used * 100 / $max}")
    context="${percent}% (${used}/${max})"
  else
    context="?"
  fi

  # Get git branch if in a repo
  branch=""
  if git rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    branch=" | $branch"
  fi

  echo "$model | ${context} | \$${cost}${branch}"
else
  # Fallback if jq is not available
  if git rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    echo "git: $branch"
  else
    echo "claude-code"
  fi
fi
