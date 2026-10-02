#!/usr/bin/env bash

_bash_compgen_words() {
  local words="$1"
  local current="$2"
  local old_ifs="$IFS"
  IFS=$'\n'
  # shellcheck disable=SC2207
  COMPREPLY=($(compgen -W "$words" -- "$current"))
  IFS="$old_ifs"
}

_worktree_name_complete() {
  _bash_compgen_words "$(git-worktree-helper names)" "${COMP_WORDS[COMP_CWORD]}"
}

complete -F _worktree_name_complete git-worktree-cd
complete -F _worktree_name_complete git-worktree-new
complete -F _worktree_name_complete git-worktree-prune
