#!/usr/bin/env bash
set -euo pipefail

pr_number=$(gh-pr-select "review> ") || exit 1
gh pr view --comments "$pr_number"
