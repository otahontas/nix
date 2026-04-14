#!/usr/bin/env bash
set -euo pipefail

repo_url=$(gh-repo-get-url) || exit 1
echo "$repo_url" | pbcopy
echo "Copied repo URL to clipboard: $repo_url"
