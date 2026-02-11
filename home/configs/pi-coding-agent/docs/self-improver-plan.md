# Self-improver: analysis and plan

## The problem

Three disabled extensions/skills share the same goal — extract learnings from conversations and persist them as AGENTS.md updates or skills:

1. **agents-md-auto-revise** — injects a long prompt into the conversation on `agent_end` after ≥10 messages
2. **agents-md-improver** — manual skill that audits AGENTS.md quality
3. **piception** — injects "MANDATORY EVALUATION" into every system prompt, has `/piception` command that uses out-of-band LLM call to extract skills

All fail because they either:

- Pollute conversation context (auto-revise injects messages, piception modifies system prompt)
- Trigger too eagerly (piception's "NON-NEGOTIABLE" on every turn, auto-revise on every agent_end)
- Create loops (extension sends message → agent responds → triggers agent_end → extension sends again)

The extraction itself is easy. **The hard part is when and how to trigger without destroying the conversation.**

## What works in practice (prior art)

### claude-code-auto-memory (severity1)

- PostToolUse hook silently logs changed file paths (zero tokens)
- Stop hook checks dirty-files, spawns **isolated agent** in separate context window
- Agent updates CLAUDE.md, main conversation untouched
- **Why it works**: deterministic trigger (files changed → process), isolated processing, zero context cost

### Claude Code official memory (Anthropic, v2.1.32+)

- Two-tier system:
  - **Auto-memory**: model writes notes to `~/.claude/projects/<project>/memory/MEMORY.md` during sessions (cadence: first at ~10K tokens, then every ~5K tokens or 3 tool calls). First 200 lines loaded at next session start.
  - **`/remember`**: user-initiated promotion from accumulated session memories → `CLAUDE.local.md` (permanent rules). User approves each proposed addition.
- Key separation: CLAUDE.md = rules _for_ Claude (human-written). MEMORY.md = notes _by_ Claude for itself.
- **Why it works**: automatic part is just note-taking (cheap, silent). Promotion to rules is user-initiated.

### Claude Code agent memory (v2.1.33)

- `memory` frontmatter field for subagents with `user`, `project`, or `local` scope
- Each agent gets persistent memory directory that survives across sessions
- Agent reads both CLAUDE.md (project context) and own memory (agent-specific knowledge)

### Letta sleep-time agents

- Secondary agent shares memory blocks with primary, runs asynchronously in background
- Configurable frequency (every N steps)
- Generates "learned context" from raw context — the primary agent's context improves over time
- **Why it works**: processing happens when agent is idle, never interrupts active work

### Key patterns from research (NeurIPS 2025 synthesis)

- Reflection loops give large gains for small effort, but are **ephemeral unless persisted**
- "Experience replay for prompting" — store successful trajectories, reuse as examples
- Self-improvement that's integrated into the agent loop works; one-off reflection doesn't stick

## Root cause analysis

Every failed approach violates the same principle: **don't inject into the active conversation to process learnings.**

| Approach                                                        | Failure mode                                               |
| --------------------------------------------------------------- | ---------------------------------------------------------- |
| auto-revise sends `sendUserMessage` on `agent_end`              | Adds messages to conversation, consumes context, can loop  |
| piception modifies `systemPrompt` on every `before_agent_start` | Adds ~500 tokens to every turn, tells model to self-invoke |
| Any mid-conversation trigger                                    | Interrupts user's flow, model gets confused about its task |

## Design

### Core principle

**The conversation is sacred.** Never inject messages, modify system prompts, or trigger mid-conversation processing for self-improvement purposes. All extraction happens out-of-band.

### Architecture

One extension. One interface: `/learn` command.

Our `/learn` is equivalent to Claude Code's `/remember` — analyze the session, propose permanent additions. We skip the auto-memory tier: the session transcript (already stored by pi's session manager) IS the raw memory. No separate MEMORY.md needed.

#### `/learn` command

User runs `/learn` when they want to extract learnings. The command:

1. Reads session transcript from `ctx.sessionManager.getBranch()`
2. Finds AGENTS.md files in cwd and parent directories
3. Calls `complete()` from `@mariozechner/pi-ai` using the currently selected model and its API key from `ctx.modelRegistry`
4. Presents proposed AGENTS.md changes via `ctx.ui` dialogs (no conversation messages)
5. User approves/rejects each change
6. Applies approved changes to AGENTS.md files

No conversation pollution. No context cost. User is in full control.

### Why this design

| Problem                           | How it's solved                                                                                       |
| --------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Context pollution                 | Out-of-band LLM call via `complete()`, results shown via `ctx.ui` dialogs, never touches conversation |
| Loops                             | Manual trigger only, no automatic re-triggering                                                       |
| Eagerness                         | User decides when to run                                                                              |
| Multiple self-improvers competing | Single unified extension replaces all three                                                           |
| Destroying conversation flow      | No `sendUserMessage`, no `before_agent_start` modifications                                           |

### What to extract

Keep the extraction prompt focused and simple:

- Gotchas and non-obvious patterns encountered
- Commands that worked (build, test, deploy)
- Code conventions followed or discovered
- Environment quirks
- Error patterns and their solutions

Output format: proposed additions to the nearest AGENTS.md, as diffs. One line per learning. Concise.

### What NOT to do

- No system prompt injection
- No "MANDATORY EVALUATION" language
- No automatic triggers (no session-end nudge — too hard to determine "substantial" without being wrong)
- No web search during extraction
- No skill creation (just AGENTS.md updates for v1)
- No complex skill matching/deduplication logic

### Future enhancements (not for v1)

- **Auto-memory tier**: silently write observations during sessions to a memory file, `/learn` analyzes both transcript and memory. Enables cross-session pattern detection ("you've corrected this 3 times → make it a rule").
- **Session-end nudge**: once we have real usage data on what "substantial" means, add a conservative exit dialog.
- **Skill extraction**: extend `/learn` to optionally propose new skills when session clearly produced a reusable multi-step procedure.

## Implementation steps

1. Create single extension: `extensions/learn.ts`
2. Implement `/learn` command:
   - Build conversation text from session branch
   - Find AGENTS.md files (cwd + parents)
   - Read current AGENTS.md content
   - Out-of-band `complete()` call with extraction prompt
   - Parse proposed additions
   - Show each via `ctx.ui.confirm()`, apply approved ones
3. Test: run in a session, do some work, run `/learn`, verify AGENTS.md changes are sensible
4. Delete old self-improver source files:
   - `extensions/agents-md-auto-revise.ts`
   - `extensions/piception/` (directory: `index.ts`, `extraction-prompt.md`, `skill-template.md`)
   - `skills/agents-md-improver/`
5. Clean up `default.nix`:
   - Remove `agents-md-auto-revise.ts` and `piception.ts` from `disabledExtensions`
   - Remove `agents-md-improver` from `disabledSkills`
   - Remove stale entry `context-for-editor.ts` from `disabledExtensions` (file doesn't exist)
