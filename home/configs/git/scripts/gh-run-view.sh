#!/usr/bin/env bash
set -euo pipefail

runs=$(gh run list --limit 50 --json status,displayTitle,workflowName,headBranch,databaseId,startedAt,updatedAt,createdAt,conclusion)

if [ -z "$runs" ] || [ "$runs" = "[]" ]; then
  echo "No workflow runs found"
  exit 0
fi

formatted=$(echo "$runs" | jq -r '.[] |
  (.status) + " | " +
  (.displayTitle) + " | " +
  (.workflowName // "-") + " | " +
  (.headBranch // "-") + " | " +
  (.databaseId | tostring) + " | " +
  (if .startedAt == null or .startedAt == "" then "-" else .startedAt end) + " | " +
  (if .createdAt == null or .createdAt == "" then "-" else .createdAt end)')

selection=$(echo "$formatted" | fzf --prompt "runs> " --header "status | title | workflow | branch | id | started | created")

if [ -z "$selection" ]; then
  exit 0
fi

run_id=$(echo "$selection" | cut -d'|' -f5 | xargs)
gh run view "$run_id"
