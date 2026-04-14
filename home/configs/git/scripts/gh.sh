#!/usr/bin/env bash
set -euo pipefail

__gh_pr_select() {
  local prompt="${1:-}> "
  local prs
  prs=$(gh pr list --state open --limit 100 --json number,title,headRefName,createdAt)

  if [ -z "$prs" ] || [ "$prs" = "[]" ]; then
    echo "No open pull requests found" >&2
    return 1
  fi

  local formatted
  formatted=$(echo "$prs" | jq -r '.[] | "\(.number) | \(.title) | \(.headRefName) | \(.createdAt | split(\"T\")[0] + \" \" + .createdAt | split(\"T\")[1] | split(\".\")[0])"')

  local selection
  selection=$(echo "$formatted" | fzf --prompt "$prompt" --header "id | title | branch | created at")

  if [ -z "$selection" ]; then
    return 1
  fi

  echo "$selection" | cut -d'|' -f1 | xargs
}

__gh_pr_get_url() {
  local url
  url=$(gh pr view --json url --jq .url 2>/dev/null)
  if [ -z "$url" ]; then
    echo "No pull request found for the current branch" >&2
    return 1
  fi
  echo "$url"
}

__gh_pr_copy_url() {
  local pr_url
  pr_url=$(__gh_pr_get_url) || return 1
  echo "$pr_url" | pbcopy
  echo "Copied PR URL to clipboard: $pr_url"
}

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

__gh_pr_review() {
  local pr_number
  pr_number=$(__gh_pr_select "review> ") || return 1
  gh pr view --comments "$pr_number"
}

__gh_pr_approve_and_merge() {
  local pr_number
  pr_number=$(__gh_pr_select "approve+merge> ") || return 1
  echo "Approving PR #$pr_number..."
  gh pr review "$pr_number" --approve
  echo "Merging PR #$pr_number..."
  gh pr merge "$pr_number" --auto
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

__gh_release_slack() {
  local pr_number="$1"

  if [ -z "$pr_number" ]; then
    echo "Usage: gh-release-slack <pr_number>" >&2
    return 1
  fi

  local pr_data
  pr_data=$(gh pr view "$pr_number" --json title,body --template '{{ .title }}\n{{ .body }}' 2>/dev/null)

  if [ -z "$pr_data" ]; then
    echo "Failed to read PR $pr_number." >&2
    return 1
  fi

  local title release_notes
  title=$(echo "$pr_data" | head -n1)
  release_notes=$(echo "$pr_data" | tail -n +2)

  if ! echo "$title" | grep -qE '^Release\s+.+?\s+\S+$'; then
    echo "PR $pr_number title \"$title\" does not match \"Release <service> <version>\" format." >&2
    return 1
  fi

  local service version output
  service=$(echo "$title" | sed -E 's/^Release\s+(.+?)\s+\S+$/\1/')
  version=$(echo "$title" | awk '{print $NF}')

  if [ -z "$(echo "$release_notes" | xargs)" ]; then
    echo "PR $pr_number release notes are empty." >&2
    return 1
  fi

  output="Released $service \`$version\`

$release_notes"
  echo "$output"
  echo "$output" | pbcopy
  echo "Copied to clipboard." >&2
}

case "$(basename "$0")" in
gh-pr-select) __gh_pr_select "$@" ;;
gh-pr-get-url) __gh_pr_get_url "$@" ;;
gh-pr-copy-url) __gh_pr_copy_url "$@" ;;
gh-repo-get-url) __gh_repo_get_url "$@" ;;
gh-repo-copy-url) __gh_repo_copy_url "$@" ;;
gh-pr-review) __gh_pr_review "$@" ;;
gh-pr-approve-and-merge) __gh_pr_approve_and_merge "$@" ;;
gh-run-view) __gh_run_view "$@" ;;
gh-release-slack) __gh_release_slack "$@" ;;
esac
