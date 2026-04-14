#!/usr/bin/env bash
set -euo pipefail

branch_name="$1"

if [ -z "$branch_name" ]; then
  echo "Usage: git-worktree-prune <branch_name>"
  exit 1
fi

repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -z "$repo_root" ]; then
  echo "Error: Not in a git repository"
  exit 1
fi

worktree_path="$repo_root/.worktrees/$branch_name"

if [ ! -d "$worktree_path" ]; then
  echo "Error: Could not find worktree for branch '$branch_name'"
  echo ""
  echo "Available worktrees:"
  git worktree list
  exit 1
fi

echo "Removing worktree: $worktree_path"
git worktree remove "$worktree_path" --force
echo "✓ Worktree removed"

if git show-ref --verify --quiet "refs/heads/$branch_name"; then
  echo "Deleting branch: $branch_name"
  git branch -D "$branch_name"
  echo "✓ Branch deleted"
fi
