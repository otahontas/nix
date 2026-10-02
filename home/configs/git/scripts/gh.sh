#!/usr/bin/env bash
set -euo pipefail

__gh_repo_get_url() {
  local url
  url=$(gh repo view --json url --jq .url 2>/dev/null)
  if [ -z "$url" ]; then
    echo "Could not get repository URL" >&2
    return 1
  fi
  echo "$url"
}

__gh_repo_copy_url() {
  local repo_url
  repo_url=$(__gh_repo_get_url) || return 1
  echo "$repo_url" | pbcopy
  echo "Copied repo URL to clipboard: $repo_url"
}

__gh_run_view() {
  local runs
  runs=$(gh run list --limit 50 --json status,displayTitle,workflowName,headBranch,databaseId,startedAt,updatedAt,createdAt,conclusion)

  if [ -z "$runs" ] || [ "$runs" = "[]" ]; then
    echo "No workflow runs found"
    return 0
  fi

  local formatted
  formatted=$(echo "$runs" | jq -r '.[] |
    (.status) + " | " +
    (.displayTitle) + " | " +
    (.workflowName // "-") + " | " +
    (.headBranch // "-") + " | " +
    (.databaseId | tostring) + " | " +
    (if .startedAt == null or .startedAt == "" then "-" else .startedAt end) + " | " +
    (if .createdAt == null or .createdAt == "" then "-" else .createdAt end)')

  local selection
  selection=$(echo "$formatted" | fzf --prompt "runs> " --header "status | title | workflow | branch | id | started | created")

  if [ -z "$selection" ]; then
    return 0
  fi

  local run_id
  run_id=$(echo "$selection" | cut -d'|' -f5 | xargs)
  gh run view "$run_id"
}

case "$(basename "$0")" in
gh-repo-get-url) __gh_repo_get_url "$@" ;;
gh-repo-copy-url) __gh_repo_copy_url "$@" ;;
gh-run-view) __gh_run_view "$@" ;;
esac
