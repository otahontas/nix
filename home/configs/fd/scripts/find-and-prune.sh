#!/usr/bin/env bash
set -euo pipefail

pattern="$1"
if [ -z "$pattern" ]; then
  echo "Usage: find-and-prune <pattern>"
  exit 1
fi

echo "This will delete all files/directories matching: $pattern"
read -r -p "Are you sure? [y/N] " response
case "$response" in
[yY] | [yY][eE][sS])
  fd -H "$pattern" --exec rm -rf
  ;;
*)
  echo Cancelled
  ;;
esac
