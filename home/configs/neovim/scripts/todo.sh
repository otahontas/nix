#!/usr/bin/env bash
set -euo pipefail

__todo_path() {
  if [ -z "${TODO_FILE_LOCATION:-}" ]; then
    echo "Error: TODO_FILE_LOCATION environment variable not set" >&2
    return 1
  fi
  echo "$TODO_FILE_LOCATION"
}

__todo() {
  local p
  p=$(__todo_path) || return 1
  nvim "$p"
}

case "$(basename "$0")" in
todo_path) __todo_path "$@" ;;
todo) __todo "$@" ;;
esac
