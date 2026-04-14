#!/usr/bin/env bash
set -euo pipefail

if [ -z "$1" ]; then
  echo "Usage: nukeport <port>"
  exit 1
fi

pids=$(lsof -ti :"$1" | sort -u)

if [ -z "$pids" ]; then
  echo "No process found on port $1"
  exit 0
fi

for pid in $pids; do
  echo "Killing PID $pid on port $1"
  kill -9 "$pid"
done

echo "✓ Port $1 freed"
