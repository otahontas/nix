#!/usr/bin/env bash
set -euo pipefail

if [ -n "$1" ]; then
  lsof -iTCP -sTCP:LISTEN -n -P | grep -i "$1"
else
  lsof -iTCP -sTCP:LISTEN -n -P
fi
