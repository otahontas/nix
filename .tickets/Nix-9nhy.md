---
id: Nix-9nhy
status: closed
deps: []
links: []
created: 2026-04-10T09:51:04Z
type: feature
priority: 2
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Add unlimited 429 retries with capped exponential backoff for pi

Pi's auto-retry in `agent-session.js` gives up after 3 attempts on ALL retryable errors (429, 500-504, network errors). For 429/rate-limit errors, it should retry indefinitely with exponential backoff capped at 15 minutes.

Current behavior (`agent-session.js` `_handleRetryableError`):

- `maxRetries=3` applies uniformly to all error types
- Backoff: `baseDelayMs * 2^(attempt-1)`, default sequence: 2s → 4s → 8s, then gives up
- No cap on the exponential backoff delay — with unlimited retries, delays grow unbounded

Can't be done via extension — retry events aren't exposed to extensions, no hook to override internal logic.

Implementation: nix patch in `default.nix` against `dist/core/agent-session.js`, two changes in `_handleRetryableError`:

1. **Skip retry cap for 429s**: when the error matches `/429|rate.?limit|too many requests/i`, skip the `maxRetries` check entirely (retry forever). Other errors keep the existing cap.
2. **Cap the backoff**: change `delayMs = baseDelayMs * 2^(attempt-1)` to add `Math.min(delayMs, 900000)` so it plateaus at 15min.

Then update `settings.json` to set `baseDelayMs: 1000` (start at 1s instead of 2s).

Relevant files:

- nix store `dist/core/agent-session.js`: `_isRetryableError`, `_handleRetryableError`, delay calculation
- `home/configs/pi-coding-agent/default.nix`: nix derivation (add `postPatch` or `sed` in `installPhase`)
- `home/configs/pi-coding-agent/settings.json`: add `retry.baseDelayMs: 1000`

Note: patches break on pi version upgrades. If we want this long-term, file upstream PR at `github.com/badlogic/pi-mono`.

## Acceptance criteria

1. 429 errors retry indefinitely with exponential backoff capped at 15min
2. Non-429 retryable errors (500-504, network) still cap at `maxRetries=3`
3. `devenv tasks run home:apply` succeeds with the patched derivation
4. `pi -p "test"` works after patch (smoke test)

## Blocking

- Nix-baay [open] Remove work-tickets.sh outer retry loop

## Notes

**2026-04-10T11:10:11Z**

Patched agent-session.js via substituteInPlace in default.nix: (1) skip maxRetries cap for 429/rate-limit errors so they retry indefinitely, (2) cap delay at maxDelayMs (900000ms/15min). Set retry.baseDelayMs=1000 and retry.maxDelayMs=900000 in settings.json. All 4 ACs verified: patch applied, non-429 still capped at 3, home:apply succeeds, smoke test passes.
