#!/usr/bin/env bash
set -euo pipefail

if [ -z "${DAILY_FOLDER_LOCATION:-}" ]; then
  echo "Error: DAILY_FOLDER_LOCATION environment variable not set" >&2
  exit 1
fi

today=$(date "+%F")
daily_file="$DAILY_FOLDER_LOCATION/$today.md"
template_file="$DAILY_FOLDER_LOCATION/daily_template.txt"

if [ ! -e "$daily_file" ]; then
  if [ ! -e "$template_file" ]; then
    echo "Error: daily template not found at $template_file" >&2
    exit 1
  fi
  sed "s/<YYYY-MM-DD>/$today/g" "$template_file" >"$daily_file"
fi

echo "$daily_file"
