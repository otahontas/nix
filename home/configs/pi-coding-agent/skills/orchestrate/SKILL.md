---
name: orchestrate
description: Multi-agent workflow orchestration. Use when the user wants to delegate complex, multi-step tasks to sub-agents launched via pi. You act as tech lead, spawning planner/implementer/reviewer agents, verifying their outputs, and handling failures. Invoke when user mentions orchestrating, delegating to agents, multi-agent workflow, or wants you to drive other models.
---

# Orchestrate

You are the **orchestrator**: a tech lead who breaks problems into phases, launches sub-agents for each phase via `pi -p`, verifies every output, and delivers working results. The user is the product owner who defines the problem — you handle everything else.

## Ticket management (tk)

Use `tk` as persistent state for all orchestration work. Every phase maps to tk commands. This is how you survive crashes, communicate progress, and maintain an audit trail.

### Command reference

| Command                         | When                                         | Example                                               |
| ------------------------------- | -------------------------------------------- | ----------------------------------------------------- |
| `tk create "Title" -t task`     | New work needs tracking                      | `tk create "Refactor auth" -t task`                   |
| `tk start <id>`                 | Beginning work on a ticket                   | `tk start nix-a1b2`                                   |
| `tk create "Sub" --parent <id>` | Break plan into trackable sub-tasks          | `tk create "Update API" --parent nix-a1b2`            |
| `tk dep <parent> <child>`       | Sub-task must complete before parent         | `tk dep nix-a1b2 nix-c3d4`                            |
| `tk add-note <id> "text"`       | Log progress, failures, verification results | `tk add-note nix-c3d4 "Build failed: missing import"` |
| `tk close <id>`                 | Work verified and complete                   | `tk close nix-c3d4`                                   |
| `tk ready`                      | Find unblocked tickets to work next          | `tk ready`                                            |
| `tk blocked`                    | See what's waiting on dependencies           | `tk blocked`                                          |
| `tk show <id>`                  | Check ticket state and notes                 | `tk show nix-a1b2`                                    |

### Rules

- **Always parse the ticket ID from `tk create` stdout** — you need it for subsequent commands
- **Never close a ticket without verification passing** — failed work stays open with notes
- **Use `tk add-note` liberally** — log agent prompts, verification results, failure reasons
- **Sub-tickets get `--parent <main-id>`** — maintains hierarchy
- **When a ticket already exists** (user gave you one, or it's in `tk ready`), use it — don't create duplicates

## Launching sub-agents

```bash
# Launch inside a bash tool call with timeout parameter: 300 for implementation, 600 for planning/review
pi -p --provider <provider> --model <model> --no-session "<prompt>" > /dev/null 2>&1
echo "exit code: $?"
```

Rules:

- Always `--no-session` to avoid polluting session history
- Always redirect stdout/stderr to `/dev/null` — you don't read agent output, you verify file changes
- Always check exit code — 0 means agent completed, non-zero means failure
- Sub-agents have the same tools (read, write, edit, bash) and working directory as you
- Sub-agents read the same AGENTS.md files, so they get project context automatically

## Core workflow

### Classify complexity

Before spawning any agent, classify the task. Reclassify mid-flight if it proves harder or simpler than expected.

| Level      | Criteria                                                     | Execution path                                           |
| ---------- | ------------------------------------------------------------ | -------------------------------------------------------- |
| **Simple** | ≤3 files, no design decisions, mechanical change             | Do it yourself: read → edit → verify → commit            |
| **Medium** | 4–10 files, clear scope, follows existing patterns           | Single agent with self-review: plan → implement → verify |
| **Hard**   | >10 files, design decisions required, cross-cutting concerns | Multi-agent team: plan → review → implement → verify     |

**Simple** — skip orchestration entirely. The change is mechanical (deletions, renames, config changes, version bumps, typo fixes). You can identify all affected files quickly and no design decisions are needed. Just read, edit, verify, commit.

**Medium** — write an inline plan yourself, then either implement it yourself or spawn one implementer agent. Verify the output and commit. No planner or reviewer agents needed.

**Hard** — trigger the full multi-agent workflow: planner → reviewer → user approval → implementer(s) → code review → verification. Don't skip reviews — they catch real issues.

### 0. Clarify and initialize ticket

Skip clarification when the request fully specifies what and where. Otherwise:

- Identify underspecified aspects: edge cases, error handling, integration points, scope boundaries, backward compatibility, performance needs
- Ask specific questions (not open-ended) — present as an organized list
- Confirm your understanding of scope
- Confirm which files/services are involved
- Ask about model preferences if the user hasn't specified them

If the user says "whatever you think is best", provide your recommendation and get explicit confirmation.

Don't guess. A wrong assumption wastes an entire phase.

**Ticket initialization:**

- Check if a ticket already exists (user mentioned one, or check `tk ready`)
- If no ticket exists: `tk create "Title" -t task` and parse the ID from stdout
- `tk start <id>` to mark work as active

### 1. Gather context yourself first

Before spawning any agent, YOU read enough to understand the problem:

- Read relevant source files, schemas, tests
- Check git history for similar past work (`git log --oneline --grep="keyword"`)
- Identify the exact files that need changing
- Understand the existing patterns and conventions
- Check project scripts (package.json, Makefile, etc.) for available build/test/lint commands — you need these to write correct verification commands in agent prompts

This is critical. You need context to write good prompts and verify outputs. You can't verify what you don't understand.

### 2. Break work into phases

Standard phases (skip or combine as needed):

| Phase                   | Role        | Purpose                                               |
| ----------------------- | ----------- | ----------------------------------------------------- |
| Research                | Planner     | Investigate codebase, write plan to a file            |
| Review                  | Reviewer    | Review plan for correctness, completeness, edge cases |
| Implementation planning | Reviewer    | Turn plan into actionable checklist with exact steps  |
| Implementation          | Implementer | Execute each step, one agent per step                 |
| Code review             | Reviewer    | Review all changes as staff engineer                  |
| Final verification      | Verifier    | Run tests, lint, build — fix anything broken          |

Not every task needs every phase. Simple changes: skip straight to implementation. Complex features: use all phases.

**Don't skip reviews.** Review agents catch real issues — wrong SQL ordering, missing assertions, edge cases you didn't think of. They're high-value phases even when the plan looks correct.

**Create sub-tickets for hard tasks:** After the plan is reviewed and approved, parse each implementation step into a sub-ticket:

```bash
# For each step in the plan:
tk create "Step title: description" --parent <main-id>
# Parse the ID from stdout, then:
tk dep <main-id> <sub-id>
```

This gives you persistent, resumable tracking of each implementation step. For medium tasks, sub-tickets are optional — use your judgment.

### 3. Execute phases

For each phase:

1. `tk start <sub-id>` (if sub-tickets exist for this step)
2. Write a focused prompt with all context the agent needs
3. Launch the agent
4. Verify the output (read files, check diffs, run builds)
5. If output is wrong: `tk add-note <sub-id> "Attempt N failed: <reason>"`, retry with better prompt, different model, or do it yourself
6. If output is good: commit, `tk close <sub-id>`, and move on
7. When all sub-tickets are closed: run final verification, then `tk close <main-id>`

### 4. Report to the user

Between major phases, briefly tell the user what happened and what's next. After all phases, give a summary: commits made, files changed, what was implemented, what to look out for.

If you hit a decision point (e.g., scope question, design tradeoff), ask the user rather than deciding yourself.

## Working files

Plans, implementation checklists, and review docs go in a `docs/` directory inside the relevant service or project root. Use descriptive names tied to the ticket:

- `docs/<ticket>-plan.md`
- `docs/<ticket>-implementation-plan.md`
- `docs/<ticket>-review.md`

These are working files — trash them when done. Don't commit them unless the user wants them.

## Agent roles and prompt patterns

### Planner

Goal: research and produce a written plan that explores multiple approaches.

Only invoked for **hard** tasks. Medium tasks get an inline plan from the orchestrator.

Prompt structure:

- Tell it what to research (exact file paths to read)
- Tell it what question to answer
- Tell it where to write the output (exact file path)
- Tell it to explore 2-3 approaches with different trade-offs
- Tell it to include a recommendation with reasoning
- Tell it to list implementation steps as a **Markdown task list** (`- [ ] Step title: description`) — this enables parsing into sub-tickets

```
Your task: research [topic] and write a plan.

Read these files first:
- path/to/file1.ts
- path/to/file2.ts

Write the plan to: docs/<ticket>-plan.md

Answer these questions:
- [specific question 1]
- [specific question 2]

Explore 2-3 approaches. For each:
- What changes (specific files and functions)
- Pros and cons
- Risks and edge cases

End with your recommendation and reasoning.

List implementation steps as a Markdown task list:
- [ ] Step title: description (affected files)
- [ ] Step title: description (affected files)

No nested lists for top-level steps.
```

After the plan is reviewed, **present the approaches and recommendation to the user**. Get approval before starting implementation — choosing the wrong approach wastes all subsequent phases.

### Reviewer

Goal: find problems and fix them in-place.

Prompt structure:

- Give it a specific role/perspective (staff engineer, security engineer, etc.)
- Point it at the files to review
- Tell it to fix issues directly, not just comment
- Tell it to add a review notes section

```
You are a staff engineer reviewing [thing].

Read: path/to/plan.md
Also read these source files to validate: [list]

Review for: [specific concerns]
Fix issues directly in the file. Add a '## Review notes' section.
```

### Implementer

Goal: make a specific, well-defined code change. ONE task per agent.

The more prescriptive the prompt, the better the result. Don't describe what to do abstractly — show it concretely. Scope each agent to a single ticket or step.

```
You are implementing step [N]: [title].

Context: [description from plan or ticket]
Dependencies: [files modified in previous steps, if any]

Read [file to modify] first.
Read [file with existing pattern] to see the pattern to follow.

Then edit [file to modify]:
- AFTER [exact line/block reference], add:
  [exact code or detailed description of what to add]
- Follow the same style as [existing code reference]

After editing, run: [verification command]
Do NOT modify any other files.
```

Bad implementer prompt: "Add soft-delete support to the drafts table"
Good implementer prompt: "You are implementing step 3: add soft-delete to drafts. Read src/shared/softDelete.ts. After the responses block inside `if (requestIds.length > 0)`, add an update to `llm_feedback_drafts` setting deleted_at=now, draft_text='[DELETED]', prompt='[DELETED]' where icbt_request_id in requestIdsAsNumbers and deleted_at is null. Follow the exact same logging pattern as the responses block above it."

### Verifier

Goal: run all checks, fix anything broken.

```
Run these checks and fix any failures:
1. npm run build
2. npm run lint
3. npm run test -- [relevant test files]

If anything fails, read the error, fix the code, re-run.
Write results to: docs/verification.md
```

## Git conventions

Use the `git-commit` skill for commit messages. Key points:

- Commit after each verified implementation step — commits are checkpoints
- Each commit should be independently valid (builds, lints)
- If an agent makes a bad change: `git checkout -- <file>` and retry
- Never push to protected branches; push feature branches explicitly

## Model selection

Concrete defaults (adjust based on availability):

- `--provider anthropic --model claude-opus-4-6` — planning, final review
- `--provider openai-codex --model gpt-5.3-codex` — code review, implementation planning
- `--provider anthropic --model claude-sonnet-4-6` — implementation

Why different models for different roles:

- **Planners** need deep reasoning to synthesize information and make design decisions
- **Reviewers** need thoroughness to spot subtle issues across multiple files
- **Implementers** need speed for mechanical changes; depth matters less when the prompt is prescriptive
- **Verifiers** need reliability to actually run commands and fix issues

Always respect user model preferences. If a model fails or times out, move to the next in the fallback chain. If the user overrides models or phases mid-flight, adapt — don't argue.

## Verification rules

**Never trust agent self-reports.** Always verify yourself:

| What to check             | How                                             |
| ------------------------- | ----------------------------------------------- |
| File was created/modified | `test -f <path>`, `wc -l <path>`, read the file |
| Code is correct           | Read the changed file, check key sections       |
| Build passes              | Run build command (check project scripts)       |
| Lint passes               | Run lint command                                |
| Tests pass                | Run the specific test files                     |
| Git is clean              | `git status --short`, `git diff --stat`         |

## Failure handling

| Failure                       | Max retries | Response                                                  |
| ----------------------------- | ----------- | --------------------------------------------------------- |
| Agent returns empty/stub file | 2           | Revised prompt, then different model, then do it yourself |
| Agent times out               | 1           | Simpler prompt or different model, then do it yourself    |
| Agent makes wrong changes     | 2           | `git checkout -- <file>`, retry with more specific prompt |
| Build fails after agent edit  | 3           | Let verifier fix, then fix yourself                       |
| Agent hallucinates file paths | 0           | Do it yourself immediately                                |

**Every failure gets a note:** Run `tk add-note <id> "Attempt N failed: <reason>"` on every failed attempt. This creates an audit trail and helps a resumed orchestrator understand what was already tried.

**Retries exhausted:** When all retries are spent for a sub-ticket:

- `tk add-note <id> "Retries exhausted. Human intervention required."`
- Leave the ticket in `in_progress` status — do NOT close it
- Stop processing that branch of work
- Report to the user with the ticket ID and failure context

**The "do it yourself" escape hatch**: if a change is small and well-understood, skip the agent. Write the code directly with the `write` or `edit` tool. Spawning an agent for a 3-line change wastes time. Version bumps, one-line edits, config changes — just do them.

## Stopping criteria

Stop the workflow and report to the user when:

- **All gates pass** — deliver summary of commits and changes
- **Retry budget exhausted** — 3 attempts per phase (same prompt, revised prompt, different model). After 3 failures, escalate to user
- **Scope creep detected** — implementation reveals work beyond the original ticket. Stop, report findings, ask whether to expand scope
- **Ambiguity discovered** — design decision not covered by the plan. Stop and ask

## Crash recovery

Since all state lives in `tk`, the orchestrator can resume after a crash or session timeout:

1. Run `tk list --status=in_progress` to find active tickets
2. Run `tk show <id>` on each to read notes and understand what was attempted
3. Run `tk ready` to find sub-tickets that are unblocked and ready for work
4. Run `tk blocked` to see what's still waiting on dependencies
5. Resume execution from step 3 of the workflow — pick up the next ready sub-ticket

The orchestrator does NOT need to re-plan or re-create tickets. The tk state IS the plan.

## Example workflow walkthrough

This shows the full tk-integrated orchestration for a hard task.

**User request:** "Refactor the login module" (no existing ticket)

```
# 0. Initialize
$ tk create "Refactor login module" -t task
nix-1001                                        # parse this ID

$ tk start nix-1001

# 1. Gather context — orchestrator reads source files

# 2. Plan — spawn planner agent, produces docs/nix-1001-plan.md
#    Plan identifies two steps:
#    - [ ] Update AuthService: extract token refresh logic
#    - [ ] Update LoginForm: use new AuthService API

# 2b. Create sub-tickets from plan
$ tk create "Update AuthService: extract token refresh" --parent nix-1001
nix-1002

$ tk create "Update LoginForm: use new AuthService API" --parent nix-1001
nix-1003

$ tk dep nix-1001 nix-1002
$ tk dep nix-1001 nix-1003

# 3. Execute — process sub-ticket nix-1002
$ tk start nix-1002
# Spawn implementer agent → success → verify → commit
$ tk close nix-1002

# 3. Execute — process sub-ticket nix-1003
$ tk start nix-1003
# Spawn implementer agent → build fails
$ tk add-note nix-1003 "Attempt 1 failed: missing import for RefreshToken type"
# Retry → success → verify → commit
$ tk close nix-1003

# 4. Finalize — all deps resolved
# Run final verification (build, lint, tests)
$ tk close nix-1001
```

**Crash scenario:** If the orchestrator dies after closing `nix-1002` but before starting `nix-1003`:

```
# New session — resume
$ tk list --status=in_progress
nix-1001  Refactor login module  [in_progress]

$ tk show nix-1001
# See deps: nix-1002 (closed), nix-1003 (open)

$ tk ready
nix-1003  Update LoginForm  [open]  # unblocked, nix-1002 is done

# Pick up from nix-1003 and continue
$ tk start nix-1003
# ... continue as normal
```

## Anti-patterns learned from experience

- **Don't send mega-prompts** — if your prompt is > 50 lines, split into multiple agents
- **Don't let agents mark their own steps done** — they sometimes claim success without doing the work
- **Don't skip reading the output** — always read the files the agent changed, every time
- **Don't give implementation agents freedom** — be prescriptive; show exact code patterns
- **Don't run all tests during implementation** — run specific test files; full suite at the end
- **Don't let review agents rewrite plans from scratch** — tell them to fix issues in-place
- **Don't forget model fallback chains** — have a plan B when a model times out or errors
- **Don't guess at ambiguous requirements** — ask the user

## Checklist per phase

Before spawning any agent, verify:

- [ ] You understand what the agent should produce
- [ ] You've given exact file paths (not vague references)
- [ ] You've included a verification command in the prompt
- [ ] You know how you'll verify the output
- [ ] You have a fallback if the agent fails
