#!/usr/bin/env bash
set -euo pipefail

prompt="${1:-}> "
prs=$(gh pr list --state open --limit 100 --json number,title,headRefName,createdAt)

if [ -z "$prs" ] || [ "$prs" = "[]" ]; then
  echo "No open pull requests found" >&2
  exit 1
fi

formatted=$(echo "$prs" | jq -r '.[] | "\(.number) | \(.title) | \(.headRefName) | \(.createdAt | split(\"T\")[0] + \" \" + .createdAt | split(\"T\")[1] | split(\".\")[0])"')

selection=$(echo "$formatted" | fzf --prompt "$prompt" --header "id | title | branch | created at")

if [ -z "$selection" ]; then
  exit 1
fi

echo "$selection" | cut -d'|' -f1 | xargs
