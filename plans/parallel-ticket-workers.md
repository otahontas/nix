# Parallel ticket workers

Investigation of how to run multiple ticket workers concurrently using git worktrees.

## Current setup

The pipeline is fully sequential:

1. `work-tickets.sh` runs in the project checkout (e.g. `~/Documents/lahin-alko/`)
2. Calls `tk ready -T ready-for-development` to pick the next ticket
3. Calls `tk start <id>` (sets status to `in_progress`)
4. Spawns `pi -p "Work on ticket $ID using your ticket-worker skill"` — **blocking, waits for pi to finish**
5. Checks if ticket was closed, retries up to 3 times
6. Loops to next ticket

Key details:

- `ticket-worker` skill says: "Work in the current checkout. No branch creation or worktree setup needed."
- `tk` stores tickets as YAML-frontmatter markdown files in `.tickets/`
- **No locking exists** — the script itself comments: `# Note: not safe to run concurrently against the same .tickets directory.`
- `.tickets/` is tracked in git (35 tickets in lahin-alko)
- `tk` supports `TICKETS_DIR` env var to override `.tickets/` location
- `pi` discovers `AGENTS.md` by walking up from cwd — worktrees at `.worktrees/<branch>/` would find the project root's `AGENTS.md`

## Concurrency problems

| Problem                     | Why it matters                                                                                                                                                     |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Race on ticket pickup       | `tk ready` + `tk start` is not atomic. Two workers could grab the same ticket.                                                                                     |
| Race on ticket state writes | `tk status`/`tk close` does `_sed_i` (sed → tmp → mv). Concurrent writes to different files are fine, but no guard against two workers touching the same file.     |
| Shared `.tickets/` location | `tk` finds `.tickets/` by walking up from `$PWD`. Worktrees are separate checkouts — they won't have `.tickets/` unless symlinked or pointed to via `TICKETS_DIR`. |
| Git conflicts               | If `.tickets/` is tracked and two workers commit status changes in different worktrees, merge conflicts on ticket markdown files.                                  |
| Project AGENTS.md discovery | Not actually a problem — pi walks up from cwd, so worktrees find the project root's `AGENTS.md`.                                                                   |

## Design options

### Option A: Dispatcher + worktrees + shared `.tickets/` (recommended)

Single dispatcher process owns ticket state; workers only do code changes.

```
work-tickets-parallel.sh (dispatcher, runs once)
├── picks ticket via tk ready (no race — only dispatcher touches tk)
├── creates worktree: git worktree add .worktrees/ticket-<id> -b ticket/<id>
├── spawns worker: cd .worktrees/ticket-<id> && TICKETS_DIR=../../.tickets pi -p "..."
├── waits for worker, checks status, closes ticket
├── merges branch back to main (or leaves it)
├── removes worktree
└── loops (up to 3 concurrent workers)
```

Pros:

- No changes to `tk` needed — dispatcher is the only thing that calls `tk ready`/`tk start`/`tk close`, zero race risk
- Worktrees give real isolation — each worker has its own filesystem, no file conflicts
- `TICKETS_DIR` already exists in `tk` — workers in worktrees can still read ticket details and add notes
- Implementation is mostly the script — `ticket-worker` skill needs a small tweak only

Cons:

- `.tickets/` in git: if worker or dispatcher commits, ticket file changes could conflict on merge. Fix: `.gitignore` it (it's local state), or dispatcher commits status changes separately before merging
- Auto-merge could fail if branches conflict. Pragmatic fix: auto-merge with `--no-edit`, leave worktree for manual resolution if it fails

### Option B: Add flock/lockf to `tk` + run N instances of work-tickets.sh

- Add `flock` (Linux) or `lockf` (macOS) around `ready`+`start` in `tk` to make them atomic
- Add locking around `close`/`status` writes
- Each `work-tickets.sh` instance creates its own worktree before spawning `pi`
- Run 3 instances: `work-tickets.sh &; work-tickets.sh &; work-tickets.sh &`

Pros:

- Simpler conceptually — just "run the existing thing 3 times"
- No dispatcher process to write

Cons:

- More complex `tk` changes — locking is platform-dependent (macOS uses `lockf`, Linux uses `flock`)
- Merge-back strategy still needs solving
- Each instance is independent — harder to get a unified view of progress

### Option C: Hybrid — lightweight dispatcher, no worktrees

Skip worktrees entirely if workers touch different files:

- Add locking to `tk`
- Run N workers in the same checkout
- Workers work on different tickets that touch different files

Pros:

- Simplest implementation — no worktree management
- No merge step

Cons:

- If two workers modify the same file, they'll step on each other
- Only safe if tickets are truly independent (no overlap in changed files)
- Not reliable in general

## Recommendation

Option A. Reasons:

1. No changes to `tk` — dispatcher is the sole state manager, no race conditions
2. Worktrees give real filesystem isolation — no file conflicts between workers
3. `TICKETS_DIR` env var already exists — minimal glue needed
4. Implementation is mostly the dispatch script + a small skill tweak

## What would need to change

| Component             | Change                                                                                                             |
| --------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `work-tickets.sh`     | Rewrite as dispatcher: manages worktrees, limits to 3 workers, handles merge/cleanup                               |
| `ticket-worker` skill | Remove "work in current checkout" rule; commit to current branch; note that `TICKETS_DIR` points to shared tickets |
| `tk`                  | No changes needed                                                                                                  |
| `.tickets/` in git    | Consider `.gitignore`-ing it (runtime state), or accept dispatcher commits status changes before merge             |
| Project AGENTS.md     | May need a note about ticket branches if project conventions say "push to main"                                    |
