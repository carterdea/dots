#!/usr/bin/env bash
# Custom status line for Claude Code
# Claude Code pipes JSON data to this script via stdin
# The script outputs text to display in the status line

# Read JSON from stdin
input=$(cat)

# Parse JSON using jq if available, otherwise use basic parsing
if command -v jq &> /dev/null; then
  model=$(echo "$input" | jq -r '.model.display_name // "?"')
  # used_percentage = actual current context fullness (drops after compaction)
  percent=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
  # total tokens = cumulative session throughput (input + output, always grows)
  total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
  total_out=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
  total_tok=$(( total_in + total_out ))
  cost_raw=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
  cost=$([[ -n "$cost_raw" ]] && printf "%.2f" "$cost_raw" || echo "?")

  # Format total tokens as human-readable (e.g. 125k, 1.2m)
  if [[ "$total_tok" -ge 1000000 ]]; then
    tokens=$(awk "BEGIN {printf \"%.1fm\", $total_tok / 1000000}")
  elif [[ "$total_tok" -ge 1000 ]]; then
    tokens=$(awk "BEGIN {printf \"%.0fk\", $total_tok / 1000}")
  else
    tokens="${total_tok}"
  fi

  context=$([[ -n "$percent" ]] && echo "${percent}% context" || echo "? context")
  tokens="${tokens} tokens"

  # Get git branch and PR number if in a repo
  branch=""
  if git rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    pr=$(gh pr view --json number -q '.number' 2>/dev/null)
    [[ -n "$pr" ]] && branch="$branch | #$pr"
    branch=" | $branch"
  fi

  echo "$model | ${context} | ${tokens} | \$${cost}${branch}"
else
  # Fallback if jq is not available
  if git rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git branch --show-current 2>/dev/null)
    echo "git: $branch"
  else
    echo "claude-code"
  fi
fi
