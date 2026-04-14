#!/usr/bin/env bash
set -euo pipefail

pr_number=$(gh-pr-select "approve+merge> ") || exit 1
echo "Approving PR #$pr_number..."
gh pr review "$pr_number" --approve
echo "Merging PR #$pr_number..."
gh pr merge "$pr_number" --auto
