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

TAG="ready-for-development"
MAX_RETRIES=3
COMPLETED=0
SKIPPED=0

VERIFY_PROMPT="Verify the changes made for ticket TICKET. Do the following steps in order:
1. Run 'tk show TICKET' and re-read the acceptance criteria.
2. Run 'git diff HEAD~1' to see what changed.
3. Run the project test and lint commands.
4. Check for common issues: unused imports, debug prints (console.log, print(), fmt.Println), leftover TODO comments in changed lines.
If you find any issues: run 'tk reopen TICKET' then 'tk add-note TICKET \"Verification failed: <details>\"'.
If everything looks good: do nothing, the ticket stays closed."

# Load context file if available
CONTEXT=""
if [ -f "plans/.ticket-context.md" ]; then
  CONTEXT=$(cat "plans/.ticket-context.md")
  echo "Loaded context from plans/.ticket-context.md"
fi

echo "Starting ticket runner (tag: $TAG, retries: $MAX_RETRIES, verification: on)"
# Note: not safe to run concurrently against the same .tickets directory.

while true; do
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
    WORK_PROMPT="Work on ticket $TICKET using your ticket-worker skill"
    if [ -n "$CONTEXT" ]; then
      WORK_PROMPT="Project context:\n\n$CONTEXT\n\n---\n\n$WORK_PROMPT"
    fi
    if pi -p "$WORK_PROMPT"; then
      PI_EXIT=0
    else
      PI_EXIT=$?
    fi

    # Check if ticket was closed by the agent
    STATUS=$(tk show "$TICKET" 2>/dev/null | grep '^status:' | awk '{print $2}')

    if [ "$STATUS" = "closed" ]; then
      echo "✅ $TICKET closed — running verification"

      # Run verification pass (once per closure, not retried independently)
      VERIFY_PROMPT_EXPANDED="${VERIFY_PROMPT//TICKET/$TICKET}"
      if pi -p "$VERIFY_PROMPT_EXPANDED"; then
        VERIFY_EXIT=0
      else
        VERIFY_EXIT=$?
      fi

      # Re-check status after verification
      STATUS=$(tk show "$TICKET" 2>/dev/null | grep '^status:' | awk '{print $2}')

      if [ "$STATUS" = "closed" ]; then
        echo "✅ $TICKET verified"
        COMPLETED=$((COMPLETED + 1))
        DONE=true
      else
        echo "⚠️  $TICKET reopened during verification (status: $STATUS, pi exit: $VERIFY_EXIT)"
        # DONE stays false — retry loop continues with another work attempt
      fi
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
