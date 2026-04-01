#!/usr/bin/env bash
set -euo pipefail

MAX_TICKETS="${1:-10}"
COMPLETED=0
SKIPPED=0

echo "Starting ticket runner (max: $MAX_TICKETS)"

while [ "$COMPLETED" -lt "$MAX_TICKETS" ]; do
  # Get next ready ticket
  TICKET=$(tk ready 2>/dev/null | head -1 | awk '{print $1}')

  if [ -z "$TICKET" ]; then
    echo "No more ready tickets. Done."
    break
  fi

  echo "=== Working on $TICKET ==="
  tk start "$TICKET"

  # Run pi with ticket-worker skill
  if pi -p \
    --skill ~/.pi/agent/skills/ticket-worker \
    "Work on ticket $TICKET. Start by running 'tk show $TICKET' to read the ticket details."; then
    PI_EXIT=0
  else
    PI_EXIT=$?
  fi

  # Check if ticket was closed by the agent
  STATUS=$(tk query ".[] | select(.id == \"$TICKET\") | .status" 2>/dev/null | tr -d '"')

  if [ "$STATUS" = "closed" ]; then
    echo "✅ $TICKET closed"
    COMPLETED=$((COMPLETED + 1))
  else
    echo "⚠️  $TICKET not closed (status: $STATUS, pi exit: $PI_EXIT). Moving on."
    SKIPPED=$((SKIPPED + 1))
  fi

  echo ""
done

echo "Done. Completed: $COMPLETED, Skipped: $SKIPPED"
