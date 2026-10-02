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
  local branch_name="${1:-}"
  if [ -z "$branch_name" ]; then
    echo "Usage: git-worktree-new <branch_name>" >&2
    return 1
  fi

  local root worktree_path
  root=$(repo_root) || return
  worktree_path="$root/.worktrees/$branch_name"

  echo "Creating worktree for branch: $branch_name"
  echo "Location: $worktree_path"
  mkdir -p "$root/.worktrees"

  if [ -d "$root/.git/git-crypt" ]; then
    echo "Detected git-crypt encryption"
    git -c filter.git-crypt.smudge=cat -c filter.git-crypt.clean=cat worktree add -b "$branch_name" "$worktree_path"

    local worktree_basename git_crypt_link
    worktree_basename=$(basename "$worktree_path")
    git_crypt_link="$root/.git/worktrees/$worktree_basename/git-crypt"
    if [ ! -e "$git_crypt_link" ]; then
      ln -s "$root/.git/git-crypt" "$git_crypt_link"
    fi
    git -C "$worktree_path" checkout -- . 2>/dev/null || true
  else
    git worktree add -b "$branch_name" "$worktree_path"
  fi

  local status_output
  status_output=$(git -C "$worktree_path" status --short)
  if [ -n "$status_output" ]; then
    echo "Warning: Worktree has uncommitted changes:"
    echo "$status_output"
  fi

  echo
  echo "✓ Worktree created successfully"
}

case "${1:-}" in
names) worktree_names ;;
path) worktree_path "${2:-}" ;;
new) create_worktree "${2:-}" ;;
*)
  echo "Usage: git-worktree-helper {names|path|new} [branch_name]" >&2
  exit 1
  ;;
esac
