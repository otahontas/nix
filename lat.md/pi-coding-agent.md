# Pi coding agent

Home Manager config for Pi CLI, wrapper tools, package-managed extensions, local extensions, skills, prompts, and MCP servers.

## Home Manager layout

Directory layout under `home/configs/pi-coding-agent/`.

- `default.nix` — installs Pi through `pi.nix`, wraps it with pass-backed API keys, exposes wrapper-only helper tools, symlinks local extensions/skills/prompts, and writes Pi config files
- `sources/GLOBAL_AGENTS.md` — source for global `~/.pi/agent/AGENTS.md`; see [[architecture#AGENTS.md pipeline]]
- `extensions/` — local single-file TypeScript extensions symlinked to `~/.pi/agent/extensions/`
- `skills/` — repo-owned skills symlinked to `~/.pi/agent/skills/`
- `prompts/` — `merge-worktree.md` and `security-review.md`, symlinked to `~/.pi/agent/prompts/`
- `scripts/build-session-index.sh` — launchd-backed session-history indexer with explicit Nix runtime tools
- `merge-settings.sh` — activation hook that merges repo settings and deletes stale `subagents.agentOverrides` before applying repo-managed overrides
- `settings.json` — default provider/model settings, subagent model overrides, terminal settings, shell command prefix, and unpinned Pi packages
- `mcp.json` — remote Context7, local GitHits CLI, and local chrome-devtools MCP template; `default.nix` replaces `@chromeExecutable@` with the Nix Chrome package path
- `home/flake.nix` input `pi-nix` (`github:lukasl-dev/pi.nix`) supplies the Pi package and Home Manager module
- `home/flake.nix` non-flake input `githits-cli` (`github:githits-com/githits-cli`) supplies the official guided MCP skill
- `home/flake.nix` input `otahontas-nixpkgs` (`github:otahontas/nixpkgs`) supplies `lat-md` and `plannotator`

## Wrapper and package resources

The Pi wrapper loads secrets from pass, extends `PATH`, and lets package-managed extensions supply reusable features.

- `default.nix` reads pass entries for Gemini web search, Context7, GitHits, and `LAT_LLM_KEY` before Pi starts. It exports the GitHits secret as `GITHITS_API_TOKEN`.
- `mcp.json` uses GitHits' official Pi server entry: `GitHits` name, `githits@latest` over stdio, and eager lifecycle. The process inherits `GITHITS_API_TOKEN` from the Pi wrapper.
- Wrapper-only tools include `lat.md` and `plannotator` from `otahontas-nixpkgs`, plus Poppler tools and `rtk`.
- `settings.json` defaults to `openai-codex/gpt-5.6-sol` with `xhigh` thinking and enables `openai-codex/gpt-5.6-sol`, `openai-codex/gpt-5.6-terra`, and `openai-codex/gpt-5.6-luna`.
- Bundled `scout` and `reviewer` use `openai-codex/gpt-5.6-sol`, with reviewer fallback aligned to `openai-codex/gpt-5.6-sol`.
- NPM Pi packages include `pi-mcp-adapter`, `pi-web-access`, `pi-subagents`, `pi-caveman`, `@plannotator/pi-extension`, `pi-agent-goal`, `pi-rtk-optimizer`, `@quintinshaw/pi-dynamic-workflows`, and `pi-simplify`.
- Bundled agents come from `pi-subagents` (scout, researcher, planner, worker, reviewer, oracle, context-builder, delegate); no local `agents/` directory is needed.
- Unpinned NPM packages update with `pi update --extensions`.

## Local extensions

Single-file TypeScript extensions live in `extensions/` and are symlinked to `~/.pi/agent/extensions/`.

Root `tsconfig.json` typechecks these files plus root `.pi/extensions/**/*.ts` against Pi's real package types. `prek` runs this typecheck only for staged TypeScript file changes. Root devenv follows `home/pi-nix`, whose revision lives in `home/flake.lock`.

- `stop-hook.ts` — current Pi model decides whether to nudge agent after each response, using the active thinking level and emitting in-flight events for `notify.ts`
- `guardrails.ts` — blocks non-conventional commits, `rm`, `npx`, slash-containing branch names, non-standard worktree paths, and `--no-verify` commits
- `starship-widget.ts` — starship prompt as a below-editor widget while Pi's built-in footer stays enabled
- `search-sessions.ts` — BM25 search over past Pi conversations; `read_session` only reads `.jsonl` files under the Pi sessions directory
- `name-session.ts` — names UI sessions from the first real user prompt with the current Pi model
- `clone-cmd.ts` — `/clone-cmd` clones the current branch to a new session and copies a launch command
- `notify.ts` — sends session-aware OSC 777 notifications with deterministic bodies and sanitized output

### starship widget extension

Starship prompt stays above Pi's built-in footer stats while hiding the duplicate default location line.

- `starship-widget.ts` registers a `belowEditor` widget, placing starship above the footer.
- The widget renders only the cleaned starship prompt and no fallback row while starship is loading or unavailable.
- It does not call `setFooter`; [[home/configs/pi-coding-agent/extensions/starship-widget.ts#patchFooterLocationLine]] wraps `FooterComponent.render()` to drop only the first location row.
- Built-in footer code still renders token, cache-hit, experimental, model, and extension-status rows, so upstream footer updates keep applying.
- [[home/configs/pi-coding-agent/extensions/starship-widget.ts#fetchStarship]] runs `starship prompt` with stable status, duration, and job values.

### stop-hook extension

Stop-hook gates automatic self-review with the active Pi model, so it follows the configured default model and thinking level instead of pinning a separate gatekeeper.

- [[home/configs/pi-coding-agent/extensions/stop-hook.ts#askGatekeeper]] uses `ctx.model` and sets active thinking as `reasoning` when thinking is not `off`.
- [[home/configs/pi-coding-agent/extensions/stop-hook.ts#shouldSendNudge]] still skips obvious completions and stops nudging after repeated gatekeeper failures.
- [[home/configs/pi-coding-agent/extensions/stop-hook.ts#STOP_CHECK_PROMPT]] keeps follow-ups within the requested scope, so investigation-only requests report findings instead of starting fixes.
- `agent_end` only queues the self-review prompt after tool-using turns, and shared start/end events let `notify.ts` wait for the gatekeeper.

### guardrails extension

Guardrails block unsafe or non-standard shell actions before tool calls run.

- `guardrails.ts` blocks non-conventional commit messages, `npx`/`bunx`, `rm`/`rmdir`, slash-containing branch names, non-standard worktree paths, and `git commit --no-verify`.
- Guard messages point agents to repo conventions such as `trash`, package scripts, dash-only branch names, and `.worktrees/<branch>` paths.

### search-sessions extension

Search-sessions exposes past Pi conversations through a prebuilt BM25 index.

- `search_sessions` reads `~/.cache/pi-session-index.json`, supports project/day filters, and ranks title/content matches.
- `read_session` resolves only `.jsonl` files under `~/.pi/agent/sessions` before returning condensed message pairs.
- `scripts/build-session-index.sh` builds the index from session user, assistant, and compaction text on a launchd timer.

### name-session extension

Name-session assigns display names without depending on native notifications.

Key behavior lives in [[home/configs/pi-coding-agent/extensions/name-session.ts#avoidTitleCase]], [[home/configs/pi-coding-agent/extensions/name-session.ts#generateTitle]], and [[home/configs/pi-coding-agent/extensions/name-session.ts#looksLikeRealTask]].

- In UI sessions, the first real user prompt can generate a 2-6 word session title with the current Pi model. Manual and restored names win, greetings and extension-generated prompts are skipped, and the result is guarded against session switches before `pi.setSessionName` runs.
- Generated titles are normalized after the model response: ordinary title-case words become lowercase, while acronyms, mixed-case words, and listed product names keep their casing.
- Extension-generated prompts are skipped so `stop-hook.ts` follow-ups do not rename the session.
- Title generation is best effort and never breaks the agent loop.

### clone-cmd extension

Clone-cmd creates a new Pi session from the current branch without switching the active pane.

Key behavior lives in [[home/configs/pi-coding-agent/extensions/clone-cmd.ts#copyToClipboard]].

- `/clone-cmd` copies `cd <cwd> && pi --session <session-id>` for a cloned session at the current leaf.
- The extension opens the current session file through a separate `SessionManager`, so the active pane stays on the original session.

### notify extension

Pi notifications carry useful context without model calls.

Key behavior lives in [[home/configs/pi-coding-agent/extensions/notify.ts#buildNotificationBody]], [[home/configs/pi-coding-agent/extensions/notify.ts#canWriteNativeNotification]], and [[home/configs/pi-coding-agent/extensions/notify.ts#notify]].

- `agent_end` notifications only run in interactive TTY sessions. They wait for stop-hook gatekeeper checks, then send only if Pi is idle and has no pending messages.
- `stop-hook.ts` emits shared start/end events around [[home/configs/pi-coding-agent/extensions/stop-hook.ts#shouldSendNudge]], so notification timers can cancel stale turn-complete alerts when a follow-up starts.
- Body text is deterministic: failed bash command first, then `needs input` when the final assistant message appears blocked, otherwise `done`.
- OSC 777 title/body fields collapse whitespace, remove control characters, replace semicolons, and truncate output before writing to stdout. The notifier also emits BEL so Ghostty can trigger its configured title, attention, and border bell effects.

## Package-managed behavior

Package-managed extensions provide reusable Pi behavior outside the local single-file extension set.

### pi-caveman package

Caveman response style comes from the package-managed `pi-caveman` extension instead of a local skill and AGENTS.md rule.

- Pi loads `npm:pi-caveman` from `settings.json`; the package stays unpinned so `pi update --extensions` can update it.
- The package provides `/caveman` for session-level toggles and `/caveman config` for the default level and footer status setting.
- The extension defaults new sessions to `full` caveman mode when `~/.pi/agent/caveman.json` is absent or sets `defaultLevel` to `full`.

### pi-dynamic-workflows package

Dynamic workflows come from `@quintinshaw/pi-dynamic-workflows`, enabling script-driven subagent fan-out from Pi.

- Pi loads `npm:@quintinshaw/pi-dynamic-workflows` from `settings.json`; the package stays unpinned for `pi update --extensions`.
- The package provides the `workflow` tool and commands such as `/workflows`, `/deep-research`, and `/adversarial-review`.

### pi-simplify package

Simplify reviews changed code for clarity, consistency, and maintainability through a package-managed command.

- Pi loads `npm:pi-simplify` from `settings.json`; the package stays unpinned for `pi update --extensions`.
- The package provides `/simplify`, including staged, file-specific, and reference-branch review modes.

## Skills and prompts

Repo-owned skills and prompt templates are symlinked to Pi's config directory by Home Manager.

- Local skills live under `skills/`; package-managed skills and commands stay in `settings.json`.
- GitHits' official guided skill uses its Pi setup's shared `~/.agents/skills/githits-mcp/` path. Home Manager links it directly from the locked `githits-cli` source, so `nix:update` refreshes it.
- Prompt templates live under `prompts/` and are symlinked to `~/.pi/agent/prompts/`.
- External skills installed outside this repo are user-level state, not Home Manager state here.

## Adding skills or extensions

Local additions stay under `home/configs/pi-coding-agent/`; package-managed additions stay in `settings.json`.

**Simple extensions** (single `.ts` files, no npm deps):

1. Create `extensions/name.ts`.
2. `git add` the file.
3. Commit the change; `prek` typechecks staged TypeScript files.
4. Run `devenv tasks run home:apply`.

**Simple skills** (repo-owned skill directories):

1. Create `skills/name/SKILL.md`.
2. `git add` the directory.
3. Run `devenv tasks run home:apply`.

**Complex extensions** (with npm dependencies):

- Prefer a Pi package in `settings.json`; Pi installs missing packages on startup and `pi update --extensions` updates unpinned specs.
- For first-party reusable extensions, publish an npm Pi package or use a direct git/local package source in `settings.json`.
