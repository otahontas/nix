#!/usr/bin/env bash
set -euo pipefail

pr_url=$(gh-pr-get-url) || exit 1
echo "$pr_url" | pbcopy
echo "Copied PR URL to clipboard: $pr_url"
