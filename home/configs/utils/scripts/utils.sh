#!/usr/bin/env bash
set -euo pipefail

__listening() {
  if [ -n "${1:-}" ]; then
    lsof -iTCP -sTCP:LISTEN -n -P | grep -i "$1"
  else
    lsof -iTCP -sTCP:LISTEN -n -P
  fi
}

__nukeport() {
  if [ -z "${1:-}" ]; then
    echo "Usage: nukeport <port>"
    return 1
  fi

  local pids
  pids=$(lsof -ti :"$1" | sort -u)

  if [ -z "$pids" ]; then
    echo "No process found on port $1"
    return 0
  fi

  for pid in $pids; do
    echo "Killing PID $pid on port $1"
    kill -9 "$pid"
  done

  echo "✓ Port $1 freed"
}

__trash_empty() {
  read -r -p "Empty Trash? [y/N] " response
  local case_response
  case_response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
  case "$case_response" in
  y | yes)
    if osascript -e 'tell application "Finder" to empty trash' 2>/dev/null; then
      echo "✓ Trash emptied"
    else
      echo "✗ Failed to empty trash"
      return 1
    fi
    ;;
  *)
    echo Cancelled
    ;;
  esac
}

case "$(basename "$0")" in
listening) __listening "$@" ;;
nukeport) __nukeport "$@" ;;
trash-empty) __trash_empty "$@" ;;
esac
