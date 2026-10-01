# Pi coding agent

Home Manager owns Pi CLI installation, global configuration, local extensions, skills, prompts, and MCP servers.

## Home Manager ownership

Tracked files under `home/configs/pi-coding-agent/` are source of truth for global Pi state.

`default.nix` installs the wrapped Pi package and links local resources. `settings.json` owns package and startup model defaults; activation merges it with other Pi preferences. `models.json` owns model metadata overrides; `mcp.json` owns MCP server configuration.

`home/configs/symlinks/default.nix` links Pi's session directory to iCloud-backed `~/Documents/pi-coding-agent-sessions`. Cutover requires Pi to be stopped and both stores verified; keep the original directory until the new link is confirmed.

Pi's top-level default stores provider and bare model ID separately; OpenAI GPT-6.1 Sol starts at `max`. Model cycling is not restricted. Subagents inherit the active parent model unless their own definitions or run options select another.

OpenAI GPT-6.1 Sol has an 872K context override to delay compaction beyond Pi's bundled 272K limit. This changes Pi's local limit, not the provider's account-specific limits or long-context pricing.

GPT-6.1 Sol uses Pi's built-in thinking choices without a local thinking-level override. The explicit startup default is `max`; subagents may request other supported levels. No local extension forces the paid priority service tier.

The OpenAI default requires `/login openai`. Legacy Codex models and their overrides are removed; the old `openai-codex` credential can be deleted after signing in. Built-in MCP reads the Home Manager-linked `mcp.json` without the unused adapter.

Global AGENTS and system-prompt sources follow [[architecture#AGENTS.md pipeline]]. Root `.pi/` contains repository-only extensions and lat.md skill source.

## Wrapper behavior

The Pi wrapper loads API keys from pass, exposes wrapper-only tools, and sets process-level integration required by installed packages.

It supplies Gemini, Context7, GitHits, and LAT credentials; exposes `lat.md`, Plannotator, Poppler, and `rtk`; and selects Ponytail's `ultra` default.

Plannotator and Chrome DevTools MCP use `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`, not a Nix browser. Plannotator does not select a Chrome profile.

Package-managed extensions remain unpinned and update through `pi update --extensions`.

## Local extensions

Home Manager extensions are global; root extensions apply only to this repository. Root `tsconfig.json` checks both sets against Pi's installed package types.

Model-calling extensions use `ctx.modelRegistry.complete()` so authentication, provider composition, model settings, and endpoint overrides match the active Pi session.

### Project lat extension

Project-local lat integration exposes search, section, locate, check, expand, and refs tools through direct argument execution.

`before_agent_start` requires lat search before file access. `agent_before_settle` runs `lat check` after successful runs and their recovery work, while the post-edit hook runs project `prek` after successful writes.

A failed check appends a boundary message and requests at most one correction per prompt. The next successful boundary rechecks the result without creating an unbounded correction loop; errors and aborts do not trigger corrections.

### starship widget extension

Starship renders above Pi's built-in footer and removes only its duplicate location row, leaving upstream footer status intact.

The prompt refresh waits for `agent_settled` so retries, compaction, and queued continuations finish first.

### stop-hook extension

Stop-hook asks the current session model whether another pass is needed after tool-using turns and stops after repeated gatekeeper failures.

Its prompt preserves requested scope, so investigation-only work reports findings instead of applying fixes. `agent_before_settle` waits for retries, compaction, and queued work before checking; errors and aborts are ignored.

Tool-use tracking resets for each non-extension input, so old transcript tools cannot trigger a nudge for a new tool-free prompt. One boundary message requests a continuation without inserting a synthetic user message.

### guardrails extension

Guardrails reject commands that violate repository policy: unsafe deletion, package runners, invalid commit or branch forms, non-standard worktree paths, and skipped commit hooks.

### search-sessions extension

Search-sessions reads a launchd-built BM25 index; session reads are restricted to JSONL files inside Pi's session directory.

### name-session extension

Name-session derives a short title from the first real prompt while preserving manual or restored names and ignoring extension-generated prompts.

Generation uses the active model at `minimal` when supported, otherwise its current effort. It is best effort and guarded against session switches so stale calls cannot rename another session.

### clone-cmd extension

`/clone-cmd` clones the current session leaf and copies a launch command without switching the active pane.

### notify extension

Notifications fire only after `agent_settled` in interactive sessions and use sanitized session names with a fixed `done` body.

OSC 777 plus BEL lets Ghostty own visual and attention effects without transcript parsing or model calls.

## Package-managed behavior

Reusable behavior stays package-managed instead of being copied into local extensions.

`settings.json` owns Ponytail, Caveman, subagents, Plannotator, RTK, and web access packages. Pi's built-in MCP reads `mcp.json`; pi-subagents runtime definitions remain authoritative. User-level Caveman state owns its default response style.

The legacy Codex image-generation package is not loaded, so `codex_generate_image` is unavailable. It requires the `openai-codex` credential, which the new OpenAI login does not replace.

## Verification

Offline checks verify model budgets, thinking choices, defaults, and bounded completion-hook continuations without provider requests.

Run `devenv shell -- node tests/pi-config.mjs`. Checks cover entry preservation, error and abort exits, per-prompt tool tracking, correction rechecks, and continuation limits. TypeScript checks validate the hooks against the installed Pi API.

## Skills and prompts

Home Manager links repo-owned skills and prompts into Pi's global config.

`/merge-worktree` infers its non-main target from context, commits all changes, rebases onto local `main`, fast-forwards `main`, then safely removes the merged worktree and branch without remote operations.

GitHits' guided skill comes from its locked source. Authenticated ui.sh skills refresh during Home Manager activation. Explain Diff generates self-contained HTML walkthroughs for code changes. `/plannotator-loop` revises one file in the current Pi context until approval. Skills installed outside this repo remain user state.

Impeccable's Pi skill and native engine are Nix-pinned. `IMPECCABLE_BIN` directs its launcher to the store binary, avoiding first-use downloads. Invoke with `/skill:impeccable`; updates belong to Nix, and automatic edit hooks are not installed.

### Skill refresh failure reporting

Empty or invalid ui.sh responses must identify the failed index or skill and stop activation before writing that response's files.
