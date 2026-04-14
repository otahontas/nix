#!/usr/bin/env bash
set -euo pipefail

__format_duration() {
  local secs=$1
  if [ "$secs" -ge 86400 ]; then
    local days=$((secs / 86400))
    local hours=$((secs % 86400 / 3600))
    echo "${days}d${hours}h"
  elif [ "$secs" -ge 3600 ]; then
    local hours=$((secs / 3600))
    local mins=$((secs % 3600 / 60))
    echo "${hours}h${mins}m"
  elif [ "$secs" -ge 60 ]; then
    local mins=$((secs / 60))
    local remainder=$((secs % 60))
    echo "${mins}m${remainder}s"
  else
    echo "${secs}s"
  fi
}

__git_worktree_prune() {
  local branch_name="$1"

  if [ -z "$branch_name" ]; then
    echo "Usage: git-worktree-prune <branch_name>"
    return 1
  fi

  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$repo_root" ]; then
    echo "Error: Not in a git repository"
    return 1
  fi

  local worktree_path="$repo_root/.worktrees/$branch_name"

  if [ ! -d "$worktree_path" ]; then
    echo "Error: Could not find worktree for branch '$branch_name'"
    echo ""
    echo "Available worktrees:"
    git worktree list
    return 1
  fi

  echo "Removing worktree: $worktree_path"
  git worktree remove "$worktree_path" --force
  echo "✓ Worktree removed"

  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    echo "Deleting branch: $branch_name"
    git branch -D "$branch_name"
    echo "✓ Branch deleted"
  fi
}

case "$(basename "$0")" in
format-duration) __format_duration "$@" ;;
git-worktree-prune) __git_worktree_prune "$@" ;;
esac
