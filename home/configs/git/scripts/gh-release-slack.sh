#!/usr/bin/env bash
set -euo pipefail

pr_number="$1"

if [ -z "$pr_number" ]; then
  echo "Usage: gh-release-slack <pr_number>" >&2
  exit 1
fi

pr_data=$(gh pr view "$pr_number" --json title,body --template '{{ .title }}\n{{ .body }}' 2>/dev/null)

if [ -z "$pr_data" ]; then
  echo "Failed to read PR $pr_number." >&2
  exit 1
fi

title=$(echo "$pr_data" | head -n1)
release_notes=$(echo "$pr_data" | tail -n +2)

# Parse title with format "Release <service> <version>"
if ! echo "$title" | grep -qE '^Release\s+.+?\s+\S+$'; then
  echo "PR $pr_number title \"$title\" does not match \"Release <service> <version>\" format." >&2
  exit 1
fi

service=$(echo "$title" | sed -E 's/^Release\s+(.+?)\s+\S+$/\1/')
version=$(echo "$title" | awk '{print $NF}')

if [ -z "$(echo "$release_notes" | xargs)" ]; then
  echo "PR $pr_number release notes are empty." >&2
  exit 1
fi

output="Released $service \`$version\`

$release_notes"
echo "$output"
echo "$output" | pbcopy
echo "Copied to clipboard." >&2
