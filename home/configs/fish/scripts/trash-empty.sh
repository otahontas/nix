#!/usr/bin/env bash
set -euo pipefail

read -r -p "Empty Trash? [y/N] " response
case_response=$(echo "$response" | tr '[:upper:]' '[:lower:]')
case "$case_response" in
y | yes)
  if osascript -e 'tell application "Finder" to empty trash' 2>/dev/null; then
    echo "✓ Trash emptied"
  else
    echo "✗ Failed to empty trash"
    exit 1
  fi
  ;;
*)
  echo Cancelled
  ;;
esac
