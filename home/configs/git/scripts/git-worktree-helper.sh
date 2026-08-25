#!/usr/bin/env bash
set -euo pipefail

repo_root() {
  local git_common_dir
  git_common_dir=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || {
    echo "Error: Not in a git repository" >&2
    return 1
  }
  dirname "$git_common_dir"
}

worktree_path() {
  local branch_name="${1:-}"
  if [ -z "$branch_name" ]; then
    echo "Usage: git-worktree-cd <branch_name>" >&2
    return 1
  fi

  local root path
  root=$(repo_root) || return
  path="$root/.worktrees/$branch_name"

  if [ ! -d "$path" ]; then
    echo "Error: Could not find worktree for branch '$branch_name'" >&2
    echo >&2
    echo "Available worktrees:" >&2
    git worktree list >&2
    return 1
  fi

  printf '%s\n' "$path"
}

worktree_names() {
  local root worktrees_dir
  root=$(repo_root) || return
  worktrees_dir="$root/.worktrees"
  [ -d "$worktrees_dir" ] || return 0

  local dir
  for dir in "$worktrees_dir"/*/; do
    [ -d "$dir" ] || continue
    basename "$dir"
  done
}

create_worktree() {
  local mode="$1"
  local branch_name="${2:-}"
  if [ -z "$branch_name" ]; then
    if [ "$mode" = "new" ]; then
      echo "Usage: git-worktree-new <branch_name>" >&2
    else
      echo "Usage: git-worktree-pr <branch_name>" >&2
    fi
    return 1
  fi

  local root worktree_path pr_number=""
  root=$(repo_root) || return
  worktree_path="$root/.worktrees/$branch_name"

  if [ "$mode" = "pr" ]; then
    pr_number=$(gh pr list --state open --head "$branch_name" --json number --jq '.[0].number' 2>/dev/null)
    if [ -z "$pr_number" ] || [ "$pr_number" = "null" ]; then
      echo "Error: Could not find an open PR for branch '$branch_name'" >&2
      return 1
    fi

    echo "Fetching PR #$pr_number ($branch_name)..."
    local fetch_output
    if ! fetch_output=$(git fetch origin "pull/$pr_number/head:$branch_name" 2>&1); then
      echo "$fetch_output" >&2
      return 1
    fi
    printf '%s\n' "$fetch_output" | grep -v '^From ' || true
  else
    echo "Creating worktree for branch: $branch_name"
    echo "Location: $worktree_path"
  fi

  mkdir -p "$root/.worktrees"
  if [ "$mode" = "pr" ]; then
    echo "Creating worktree for branch: $branch_name"
  fi

  if [ -d "$root/.git/git-crypt" ]; then
    echo "Detected git-crypt encryption"
    if [ "$mode" = "new" ]; then
      git -c filter.git-crypt.smudge=cat -c filter.git-crypt.clean=cat worktree add -b "$branch_name" "$worktree_path"
    else
      git -c filter.git-crypt.smudge=cat -c filter.git-crypt.clean=cat worktree add "$worktree_path" "$branch_name"
    fi

    local worktree_basename git_crypt_link
    worktree_basename=$(basename "$worktree_path")
    git_crypt_link="$root/.git/worktrees/$worktree_basename/git-crypt"
    if [ ! -e "$git_crypt_link" ]; then
      ln -s "$root/.git/git-crypt" "$git_crypt_link"
    fi
    git -C "$worktree_path" checkout -- . 2>/dev/null || true
  elif [ "$mode" = "new" ]; then
    git worktree add -b "$branch_name" "$worktree_path"
  else
    git worktree add "$worktree_path" "$branch_name"
  fi

  local status_output
  status_output=$(git -C "$worktree_path" status --short)
  if [ -n "$status_output" ]; then
    echo "Warning: Worktree has uncommitted changes:"
    echo "$status_output"
  fi

  echo
  if [ "$mode" = "new" ]; then
    echo "✓ Worktree created successfully"
  else
    echo "✓ PR #$pr_number checked out successfully"
    echo "Location: $worktree_path"
  fi
}

case "${1:-}" in
names) worktree_names ;;
path) worktree_path "${2:-}" ;;
new | pr) create_worktree "$1" "${2:-}" ;;
*)
  echo "Usage: git-worktree-helper {names|path|new|pr} [branch_name]" >&2
  exit 1
  ;;
esac
