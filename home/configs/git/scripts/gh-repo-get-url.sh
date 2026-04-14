#!/usr/bin/env bash
set -euo pipefail

url=$(gh repo view --json url --jq .url 2>/dev/null)
if [ -z "$url" ]; then
  echo "Could not get repository URL" >&2
  exit 1
fi
echo "$url"
