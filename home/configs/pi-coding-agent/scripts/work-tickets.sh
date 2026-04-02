#!/usr/bin/env bash
set -euo pipefail

# Auto-enter devenv if tk is not on PATH
if ! command -v tk &>/dev/null; then
  # Find project root with devenv.nix
  dir="$(pwd)"
  while [ "$dir" != / ]; do
    [ -f "$dir/devenv.nix" ] && break
    dir="$(dirname "$dir")"
  done
  if [ "$dir" = / ]; then
    echo "Error: no devenv.nix found in any parent directory" >&2
    exit 1
  fi
  cd "$dir"
  exec devenv shell -- "$0" "$@"
fi

MAX_TICKETS="${1:-10}"
TAG="${2:-ready-for-development}"
MAX_RETRIES=3
COMPLETED=0
SKIPPED=0

echo "Starting ticket runner (max: $MAX_TICKETS, tag: $TAG, retries: $MAX_RETRIES)"

while [ "$COMPLETED" -lt "$MAX_TICKETS" ]; do
  # Get next ready ticket with matching tag
  TICKET=$(tk ready -T "$TAG" 2>/dev/null | head -1 | awk '{print $1}')

  if [ -z "$TICKET" ]; then
    echo "No more ready tickets. Done."
    break
  fi

  tk start "$TICKET"
  ATTEMPT=0
  DONE=false

  while [ "$ATTEMPT" -lt "$MAX_RETRIES" ] && [ "$DONE" = "false" ]; do
    ATTEMPT=$((ATTEMPT + 1))
    echo "=== Working on $TICKET (attempt $ATTEMPT/$MAX_RETRIES) ==="

    # Run pi with ticket-worker skill
    if pi -p \
      --skill ~/.pi/agent/skills/ticket-worker \
      "Work on ticket $TICKET. Start by running 'tk show $TICKET' to read the ticket details. After committing, always close the ticket with 'tk close $TICKET'."; then
      PI_EXIT=0
    else
      PI_EXIT=$?
    fi

    # Check if ticket was closed by the agent
    STATUS=$(tk show "$TICKET" 2>/dev/null | grep '^status:' | awk '{print $2}')

    if [ "$STATUS" = "closed" ]; then
      echo "✅ $TICKET closed"
      COMPLETED=$((COMPLETED + 1))
      DONE=true
    else
      echo "⚠️  $TICKET not closed (status: $STATUS, pi exit: $PI_EXIT)"
    fi
  done

  if [ "$DONE" = "false" ]; then
    echo "❌ $TICKET failed after $MAX_RETRIES attempts. Skipping."
    SKIPPED=$((SKIPPED + 1))
  fi

  echo ""
done

echo "Done. Completed: $COMPLETED, Skipped: $SKIPPED"
