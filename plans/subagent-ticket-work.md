# Subagent integration for ticket-based workflow

## Current setup

Three pieces, all designed to work together:

1. **`tk`** — CLI ticket system. Tickets as markdown files in `.tickets/`, with YAML frontmatter for metadata (status, deps, tags, type). Supports dependency graphs via `tk dep`, readiness checks via `tk ready -T ready-for-development`.

2. **`ticket-creator` skill** — tells pi how to create well-structured tickets. Enforces a format contract: title, description with file hints, numbered acceptance criteria, proper use of deps vs parent, and a `ready-for-development` tag only when fully refined. Has modes for single creation, decomposition, seeding from plans, and refining backlog items.

3. **`ticket-worker` skill** — tells pi how to work a single ticket: read → explore → discover verification commands → implement incrementally → verify each acceptance criterion → commit → close. Strictly one ticket per session.

4. **`work-tickets.sh`** — the orchestration loop. Picks the next `ready-for-development` ticket, spawns `pi -p "Work on ticket $TICKET using your ticket-worker skill"` (a fresh process), checks if it got closed, retries up to 3 times, moves on. Sequential — one ticket at a time.

## Real usage (lahin-alko)

The lahin-alko project has 34 tickets. The epic `la-fup7` broke down into a dependency tree with multiple levels. Most tickets got closed successfully. One (`la-tack`) is still open. The ticket quality is high — good file hints, specific acceptance criteria that map to commands.

## What the subagent extension adds

Pi ships with a **subagent extension** (`examples/extensions/subagent/`) that's a proper custom tool:

- **Spawns separate `pi` processes** with isolated context windows
- **Three modes**: single agent, parallel (up to 8 tasks, 4 concurrent), chain (sequential with `{previous}` placeholder to pass output between steps)
- **Agent definitions** are markdown files with YAML frontmatter: `name`, `description`, `tools` (restricted subset), `model` (can use cheaper models like haiku for scouting)
- **Built-in agents**: scout (haiku, fast recon), planner (sonnet, plans), reviewer (sonnet, reviews code), worker (sonnet, full capabilities)
- **Workflow prompts**: e.g. `/implement` chains scout → planner → worker

## Integration options

### Option A: replace the shell script with an "orchestrator" agent

Instead of `work-tickets.sh` spawning raw `pi` processes, create a custom agent (or just use pi directly) that uses the subagent tool to dispatch tickets:

```
- Agent reads tk ready -T ready-for-development
- For each independent ticket, uses subagent in parallel mode
  with a "ticket-worker" agent definition
- For dependent chains, uses chain mode
```

Pros:

- Parallel ticket execution — independent tickets run simultaneously (4 concurrent)
- Context stays in the parent session for coordination
- Can dynamically adjust strategy (parallel vs sequential) based on dep graph
- Streaming progress visible in the TUI
- No shell script needed

Cons:

- The subagent tool spawns child `pi` processes — these won't automatically have the ticket-worker skill loaded unless the agent definition includes its full instructions
- Cost: running multiple agents in parallel means multiple context windows burning tokens
- The parent agent's context grows with the results from each subagent, which could hit limits if working many tickets

### Option B: keep the script, enhance with subagent per-ticket

Keep `work-tickets.sh` as the outer loop but have each ticket session use subagents internally:

```
- ticket-worker reads the ticket
- Uses scout to explore the codebase
- Uses planner to create an implementation plan
- Uses worker to implement
- Uses reviewer to verify acceptance criteria
```

This is basically the `/implement-and-review` workflow prompt applied to each ticket.

Pros:

- Incremental improvement over current setup — script stays the same
- Each ticket gets structured exploration → planning → implementation → review
- Cheaper model (haiku) for scouting saves tokens
- The ticket-worker skill already works; this just makes it better

Cons:

- Still sequential across tickets (the script is the bottleneck)
- More complexity per ticket — more moving parts that can fail
- Additional cost per ticket (multiple agent calls instead of one)

### Option C: dependency-aware parallel dispatcher (full vision)

A new skill or agent that:

1. Runs `tk ready -T ready-for-development` to get all unblocked tickets
2. Analyzes the dep graph with `tk dep tree`
3. Dispatches independent tickets as parallel subagent tasks
4. As each completes, checks for newly unblocked tickets
5. Loops until nothing is left

```
Round 1: [ticket-A, ticket-B, ticket-C] in parallel (no deps)
Round 2: [ticket-D, ticket-E] in parallel (were blocked on A, B)
Round 3: [ticket-F] (was blocked on D, E)
```

This could be a new skill (`ticket-batch-worker`) or an agent definition used with the subagent tool from a parent pi session.

Pros:

- Maximum parallelism — independent work happens simultaneously
- Respects the dependency graph automatically
- Fast for projects with many small independent tickets

Cons:

- Most complex to build and debug
- File conflict risk if parallel agents touch the same files (the subagent extension has `withFileMutationQueue` but only within a single pi process)
- tk isn't concurrency-safe (the script even notes "not safe to run concurrently against the same .tickets directory")
- Need to solve the `.tickets/` directory locking issue

### Option D: hybrid — script handles concurrency, subagents handle the work

Extend `work-tickets.sh` to run multiple `pi` processes in parallel (background jobs), but use the subagent tool within each for structured work:

```bash
# Pick up to 4 independent tickets
# Launch them as parallel background pi processes
# Wait for batch, then pick next batch
```

Pros:

- Script already handles the outer loop; add `&` and `wait` for parallelism
- No need for subagent at all for the dispatching layer
- Can use subagents within each pi session for structured exploration

Cons:

- Still the `.tickets/` concurrency issue — multiple pi processes writing to the same ticket files
- Would need file locking or a tk command that's safe for concurrent access

## Key blocker: `.tickets/` concurrency

The main blocker for any parallel approach is that `tk` reads and writes markdown files directly — two agents closing tickets simultaneously could race. Options:

- Add a lock file mechanism to `tk` (flock-based)
- Use `tk` commands atomically (they're fast) and accept the small race window
- Have a single coordinator that dispatches work but serializes all `tk` state changes

## Recommendation

**Option B is the highest-value, lowest-risk first step.** Keep the script, create a "ticket-worker" agent definition that uses chain mode (scout → worker, or scout → planner → worker), and have the script invoke pi with that agent. You get:

- Structured exploration with cheap haiku for scouting
- Better quality implementation (the plan step catches issues early)
- No concurrency issues — still one ticket at a time
- Minimal changes to existing setup

Then if you want parallelism later, **Option D** (parallel background `pi` processes with file locking in `tk`) is the pragmatic path. Options A/C are interesting but the subagent tool is really designed for within-session delegation, not as a batch job dispatcher — the shell script is better at that job.
