#!/usr/bin/env bash
set -euo pipefail

if [ -z "${TODO_FILE_LOCATION:-}" ]; then
  echo "Error: TODO_FILE_LOCATION environment variable not set" >&2
  exit 1
fi
echo "$TODO_FILE_LOCATION"
