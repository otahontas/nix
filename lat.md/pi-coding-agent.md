# Pi coding agent

Home Manager owns Pi CLI installation, global configuration, local extensions, skills, prompts, and MCP servers.

## Home Manager ownership

Tracked files under `home/configs/pi-coding-agent/` are source of truth for global Pi state.

`default.nix` installs the wrapped Pi package and links local resources. `settings.json` owns package, model, and subagent defaults; `models.json` owns model metadata overrides; `mcp.json` owns MCP server configuration.

`home/configs/symlinks/default.nix` links Pi's session directory to iCloud-backed `~/Documents/pi-coding-agent-sessions`. Cutover requires Pi to be stopped and both stores verified; keep the original directory until the new link is confirmed.

Pi's top-level default stores provider and bare model ID separately; GPT-6 Sol starts at `high`. Per-model defaults and model cycling select Sol at `high` and Astra at `max`. Subagents use Sol with package-defined thinking levels, clamped to the configured choices.

Both OpenAI Codex models have an 872K context override to delay compaction. Their published context window is 1,050,000 tokens; Pi's bundled 272K value matches the higher-priced long-context threshold, not the model's full capacity. Account-specific Codex limits still apply.

Model metadata restricts thinking choices to `high`, `xhigh`, and `max`; unsupported lower requests clamp to `high`, including subagents. This affects both the picker and cycling. No local extension forces the paid priority service tier.

Global AGENTS and system-prompt sources follow [[architecture#AGENTS.md pipeline]]. Root `.pi/` contains repository-only extensions and lat.md skill source.

## Wrapper behavior

The Pi wrapper loads API keys from pass, exposes wrapper-only tools, and sets process-level integration required by installed packages.

It supplies Gemini, Context7, GitHits, and LAT credentials; sets the Plannotator browser profile; exposes `lat.md`, Plannotator, Poppler, and `rtk`; and selects Ponytail's `ultra` default.

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

`settings.json` owns Ponytail, Caveman, Codex image generation, subagents, MCP adapter, Plannotator, RTK, and web access packages. pi-subagents runtime definitions remain authoritative; user-level Caveman state owns its default response style.

`pi-codex-image-gen` supplies `codex_generate_image` and the `imagegen` skill, reusing Pi's Codex login rather than API-key billing. Impeccable can select this tool without per-prompt routing instructions.

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
