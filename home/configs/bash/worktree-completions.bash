#!/usr/bin/env bash

__git_pr_branches_bash() {
  local prs
  prs=$(gh pr list --state open --json number,title,author,createdAt,headRefName --limit 50 2>/dev/null)
  [ -z "$prs" ] && return
  jq -r '.[] | "\(.headRefName)"' <<<"$prs"
}

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

_pr_branch_complete() {
  _bash_compgen_words "$(__git_pr_branches_bash)" "${COMP_WORDS[COMP_CWORD]}"
}

complete -F _worktree_name_complete git-worktree-cd
complete -F _worktree_name_complete git-worktree-new
complete -F _worktree_name_complete git-worktree-prune
complete -F _pr_branch_complete git-worktree-pr
