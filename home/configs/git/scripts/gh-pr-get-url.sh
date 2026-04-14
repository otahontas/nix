#!/usr/bin/env bash
set -euo pipefail

url=$(gh pr view --json url --jq .url 2>/dev/null)
if [ -z "$url" ]; then
  echo "No pull request found for the current branch" >&2
  exit 1
fi
echo "$url"
