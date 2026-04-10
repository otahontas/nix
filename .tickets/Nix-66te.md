---
id: Nix-66te
status: closed
deps: []
links: []
created: 2026-04-10T08:43:31Z
type: task
priority: 2
assignee: Otto Ahoniemi
tags: ready-for-development
---

# Add exponential backoff with unlimited retries for 429 errors in work-tickets.sh

When a model returns HTTP 429 (rate limit), the work-tickets.sh runner quits after 3 attempts with `MAX_RETRIES=3`. Instead, it should retry indefinitely with exponential backoff so long-running ticket sessions don't abort on transient rate limits.

The `pi` CLI itself already retries 3 times internally — that's fine. This ticket is about the outer retry loop in the shell script wrapping `pi` calls.

Current behavior in `work-tickets.sh`:

- `MAX_RETRIES=3` caps attempts at 3, then marks the ticket as failed/skipped
- No delay between retries

Desired behavior:

- Remove the hard cap on retries for 429-related failures
- Add exponential backoff: 5s → 10s → 30s → 1min → 2min → 5min, capped at 5min
- Only skip a ticket after max retries for non-429 failures (agent bugs, logic errors)
- Print the backoff wait time so the user can see what's happening

Relevant file: `home/configs/pi-coding-agent/scripts/work-tickets.sh` — specifically the `MAX_RETRIES` constant and the retry `while` loop (~lines 50–95).

## Acceptance criteria

1. On 429-related pi exit, work-tickets.sh retries indefinitely with exponential backoff (5s → 10s → 30s → 1min → 2min → 5min cap)
2. Non-429 failures still respect `MAX_RETRIES=3` and skip the ticket after exhausting retries
3. Backoff wait time is printed to stdout (e.g., "⏳ Rate limited, waiting 30s before retry...")
4. Existing ticket lifecycle (start → work → verify → close) is unchanged
5. `bash -n work-tickets.sh` passes (no syntax errors)

## Notes

**2026-04-10T09:01:11Z**

Added exponential backoff (5s→10s→30s→1min→2min→5min cap) with unlimited retries for 429/rate-limit errors. Non-429 failures still respect MAX_RETRIES=3. Stderr from pi is captured and checked for 429/rate-limit/too-many-requests patterns. Backoff wait time is printed to stdout.
