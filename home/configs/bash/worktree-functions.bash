#!/usr/bin/env bash

git-worktree-new() {
  git-worktree-helper new "$@" || return
  local path
  path=$(git-worktree-helper path "${1:-}") || return
  cd "$path" || return
}

git-worktree-pr() {
  git-worktree-helper pr "$@" || return
  local path
  path=$(git-worktree-helper path "${1:-}") || return
  cd "$path" || return
}

git-worktree-cd() {
  local path
  path=$(git-worktree-helper path "${1:-}") || return
  cd "$path" || return
}
