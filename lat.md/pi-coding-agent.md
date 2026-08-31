# Pi coding agent

Home Manager owns Pi CLI installation, global configuration, local extensions, skills, prompts, and MCP servers.

## Home Manager ownership

Tracked files under `home/configs/pi-coding-agent/` are source of truth for global Pi state.

`default.nix` installs the wrapped Pi package and links local resources. `settings.json` owns package, model, and subagent defaults; `mcp.json` owns MCP server configuration.

Pi's top-level default stores provider and bare model ID separately; package settings such as subagents may use qualified `provider/model` strings.

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

`before_agent_start` requires lat search before file access. `agent_end` runs `lat check`, while the post-edit hook runs project `prek` after successful writes.

### fast-mode extension

Fast mode adds OpenAI's priority service tier only to the configured Sol model at `xhigh`; auxiliary model calls reuse the same payload helper.

### starship widget extension

Starship renders above Pi's built-in footer and removes only its duplicate location row, leaving upstream footer status intact.

The prompt refresh waits for `agent_settled` so retries, compaction, and queued continuations finish first.

### stop-hook extension

Stop-hook asks the current session model whether another pass is needed after tool-using turns and stops after repeated gatekeeper failures.

Its prompt preserves requested scope, so investigation-only work reports findings instead of applying fixes.

### guardrails extension

Guardrails reject commands that violate repository policy: unsafe deletion, package runners, invalid commit or branch forms, non-standard worktree paths, and skipped commit hooks.

### search-sessions extension

Search-sessions reads a launchd-built BM25 index; session reads are restricted to JSONL files inside Pi's session directory.

### name-session extension

Name-session derives a short title from the first real prompt while preserving manual or restored names and ignoring extension-generated prompts.

Generation is best effort and guarded against session switches so stale calls cannot rename another session.

### clone-cmd extension

`/clone-cmd` clones the current session leaf and copies a launch command without switching the active pane.

### notify extension

Notifications fire only after `agent_settled` in interactive sessions and use sanitized session names with a fixed `done` body.

OSC 777 plus BEL lets Ghostty own visual and attention effects without transcript parsing or model calls.

## Package-managed behavior

Reusable behavior stays package-managed instead of being copied into local extensions.

`settings.json` owns Ponytail, Caveman, subagents, MCP adapter, Plannotator, RTK, and web access packages. pi-subagents runtime definitions remain authoritative; user-level Caveman state owns its default response style.

## Skills and prompts

Home Manager links repo-owned skills and prompts into Pi's global config.

GitHits' guided skill comes from its locked source. Authenticated ui.sh skills refresh during Home Manager activation. Skills installed outside this repo remain user state.
