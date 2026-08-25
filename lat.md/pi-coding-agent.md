# Pi coding agent

Home Manager config for Pi CLI, wrapper tools, package-managed extensions, local extensions, skills, prompts, and MCP servers.

## Home Manager layout

Directory layout under `home/configs/pi-coding-agent/`.

- `default.nix` — installs Pi through `pi.nix`, wraps it with pass-backed API keys, refreshes ui.sh skills, exposes wrapper-only helper tools, symlinks local extensions/skills/prompts, and writes Pi config files
- `sources/GLOBAL_AGENTS.md` — source for global `~/.pi/agent/AGENTS.md`; see [[architecture#AGENTS.md pipeline]]
- `sources/APPEND_SYSTEM.md` — global system-prompt additions symlinked to `~/.pi/agent/APPEND_SYSTEM.md`
- `extensions/` — local single-file TypeScript extensions symlinked to `~/.pi/agent/extensions/`
- `skills/` — repo-owned skills symlinked to `~/.pi/agent/skills/`
- `prompts/` — `merge-worktree.md`, symlinked to `~/.pi/agent/prompts/`
- `scripts/build-session-index.sh` — launchd-backed session-history indexer with explicit Nix runtime tools
- `merge-settings.sh` — activation hook that merges repo settings while preserving other live keys
- `settings.json` — default provider/model settings, one shared subagent model, terminal settings, shell command prefix, and unpinned Pi packages
- `mcp.json` — remote Context7, local GitHits CLI, and local chrome-devtools MCP template; `default.nix` replaces `@chromeExecutable@` with the Nix Chrome package path
- `home/flake.nix` input `pi-nix` (`github:lukasl-dev/pi.nix`) supplies the Pi package and Home Manager module
- `home/flake.nix` non-flake input `githits-cli` (`github:githits-com/githits-cli`) supplies the official guided MCP skill
- `home/flake.nix` input `otahontas-nixpkgs` (`github:otahontas/nixpkgs`) supplies `lat-md` and `plannotator`

## Wrapper and package resources

The Pi wrapper loads secrets from pass, extends `PATH`, and lets package-managed extensions supply reusable features.

- `default.nix` reads pass entries for Gemini web search, Context7, GitHits, and `LAT_LLM_KEY` before Pi starts. It exports the GitHits secret as `GITHITS_API_TOKEN`.
- `mcp.json` uses GitHits' official Pi server entry: `GitHits` name, `githits@latest` over stdio, and eager lifecycle. The process inherits `GITHITS_API_TOKEN` from the Pi wrapper.
- Wrapper-only tools include `lat.md` and `plannotator` from `otahontas-nixpkgs`, plus Poppler tools and `rtk`.
- The wrapper sets `BROWSER` to a Nix-built launcher for Chrome `Profile 5`, the local Dev profile, so Plannotator opens there. It clears `PLANNOTATOR_BROWSER` because that variable accepts only an app name in the Pi extension on macOS.
- The wrapper sets `PONYTAIL_DEFAULT_MODE=ultra`; Ponytail keeps all other behavior at package defaults.
- `settings.json` defaults to `openai-codex/gpt-5.6-sol` with `xhigh` thinking and scopes model selection to that pair.
- `pi-subagents` uses one Sol default while builtin agent definitions control their own thinking levels.
- NPM Pi packages include `@dietrichgebert/ponytail`, `@plannotator/pi-extension`, `pi-caveman`, `pi-mcp-adapter`, `pi-rtk-optimizer`, `pi-subagents`, and `pi-web-access`.
- Builtin agents come from `pi-subagents`; package runtime discovery stays authoritative, so no local `agents/` directory is needed.
- Unpinned NPM packages update with `pi update --extensions`.

## Local extensions

Home Manager-owned TypeScript extensions live in `extensions/`; project-specific extensions live under root `.pi/extensions/`.

Home Manager symlinks its extensions to `~/.pi/agent/extensions/`. Root `tsconfig.json` typechecks both extension sets against Pi's real package types. `prek` runs this typecheck only for staged TypeScript changes. Root devenv follows `home/pi-nix`, whose revision lives in `home/flake.lock`.

Model-calling extensions use `ctx.modelRegistry.complete()` so auxiliary requests share Pi's provider composition, resolved authentication, endpoint overrides, and model configuration.

- `fast-mode.ts` — sends every `openai-codex/gpt-5.6-sol:xhigh` request through OpenAI's Fast service tier
- `stop-hook.ts` — the current session model at `xhigh` thinking decides whether to nudge after each response
- `guardrails.ts` — blocks non-conventional commits, `rm`, `npx`, slash-containing branch names, non-standard worktree paths, and `--no-verify` commits
- `starship-widget.ts` — starship prompt as a below-editor widget while Pi's built-in footer stays enabled
- `search-sessions.ts` — BM25 search over past Pi conversations; `read_session` only reads `.jsonl` files under the Pi sessions directory
- `name-session.ts` — names UI sessions from the first real user prompt with the current Pi model
- `clone-cmd.ts` — `/clone-cmd` clones the current branch to a new session and copies a launch command
- `notify.ts` — sends sanitized session-named OSC 777 completion notifications

### Project lat extension

Project-local lat integration exposes documentation tools and enforces search and sync checks during each Pi turn.

- `.pi/extensions/lat.ts` imports schemas from `typebox` and Pi APIs from the installed `@earendil-works` package family.
- Six tools wrap `lat search`, `section`, `locate`, `check`, `expand`, and `refs`; each returns Pi's required `details`, while `lat_check` throws command failures as tool errors.
- Lat and git commands run through `pi.exec()` with argument arrays, session cwd, cancellation, and no shell interpolation.
- `.pi/extensions/post-edit-hook.ts` runs project `prek` through direct argv execution after successful edit and write tool calls.
- Expansion hints use `app.tools.expand`. Custom messages normalize string or rich content and honor Pi's configured output padding.
- `before_agent_start` requires a search before file access. `agent_end` runs `lat check` and requests a follow-up only when validation fails.

### fast-mode extension

Fast mode routes Sol `xhigh` requests through OpenAI's lower-latency service tier.

- [[home/configs/pi-coding-agent/extensions/fast-mode.ts#enableFastMode]] adds `service_tier: "priority"`, the Pi 0.83-compatible name for Fast mode.
- The provider hook applies only to `openai-codex/gpt-5.6-sol` at `xhigh` thinking.
- `stop-hook.ts` and `name-session.ts` reuse the payload helper because auxiliary `modelRegistry.complete()` calls do not traverse the agent request hook.

### starship widget extension

Starship prompt stays above Pi's built-in footer stats while hiding the duplicate default location line.

- `starship-widget.ts` registers a `belowEditor` widget, placing starship above the footer.
- The widget renders only the cleaned starship prompt and no fallback row while starship is loading or unavailable.
- It does not call `setFooter`; [[home/configs/pi-coding-agent/extensions/starship-widget.ts#patchFooterLocationLine]] wraps `FooterComponent.render()` to drop only the first location row.
- Built-in footer code still renders token, cache-hit, experimental, model, and extension-status rows, so upstream footer updates keep applying.
- [[home/configs/pi-coding-agent/extensions/starship-widget.ts#fetchStarship]] runs `starship prompt` with stable status, duration, and job values.
- `agent_settled` refreshes the prompt only after retries, compaction, and queued continuations finish.

### stop-hook extension

Stop-hook gates automatic self-review with the current session model at `xhigh` thinking, matching name-session model selection.

- [[home/configs/pi-coding-agent/extensions/stop-hook.ts#askGatekeeper]] uses `ctx.model`, always passes the shared Fast-mode payload hook, and skips the nudge when no current model is available.
- [[home/configs/pi-coding-agent/extensions/stop-hook.ts#shouldSendNudge]] still skips obvious completions and stops nudging after repeated gatekeeper failures.
- [[home/configs/pi-coding-agent/extensions/stop-hook.ts#STOP_CHECK_PROMPT]] keeps follow-ups within the requested scope, so investigation-only requests report findings instead of starting fixes.
- `agent_end` queues the self-review prompt after tool-using turns, before Pi emits `agent_settled`.

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

Key behavior lives in [[home/configs/pi-coding-agent/extensions/name-session.ts#generateTitle]] and [[home/configs/pi-coding-agent/extensions/name-session.ts#cleanGeneratedTitle]].

- In UI sessions, the first non-empty user prompt can generate a 2-6 word session title with the current Pi model at Fast `xhigh`. Manual and restored names win, extension prompts are skipped, and session-switch guards prevent stale writes.
- The generation prompt returns `EMPTY` for greetings or acknowledgements and requests lowercase ordinary words; post-processing trims, unwraps, and truncates the response.
- Extension-generated prompts are skipped so `stop-hook.ts` follow-ups do not rename the session.
- Title generation is best effort and never breaks the agent loop.

### clone-cmd extension

Clone-cmd creates a new Pi session from the current branch without switching the active pane.

Key behavior lives in [[home/configs/pi-coding-agent/extensions/clone-cmd.ts#copyToClipboard]].

- `/clone-cmd` copies `cd <cwd> && pi --session <session-id>` for a cloned session at the current leaf.
- The extension opens the current session file through a separate `SessionManager`, so the active pane stays on the original session.

### notify extension

Pi notifications announce settled sessions without model calls or transcript parsing.

Key behavior lives in [[home/configs/pi-coding-agent/extensions/notify.ts#canWriteNativeNotification]] and [[home/configs/pi-coding-agent/extensions/notify.ts#notify]].

- `agent_settled` notifications run only in interactive TTY sessions, after retries, compaction, stop-hook checks, and queued continuations finish.
- The title uses the Pi session name when available, and the body is always `done`.
- OSC 777 title text collapses whitespace, removes control characters, and replaces semicolons. The notifier also emits BEL so Ghostty can trigger its configured title, attention, and border bell effects.

## Package-managed behavior

Package-managed extensions provide reusable Pi behavior outside the local single-file extension set.

### Ponytail package

Ponytail applies minimal-code guidance at `ultra` intensity while leaving other package behavior at defaults.

- Pi loads `npm:@dietrichgebert/ponytail` from `settings.json`.
- The Pi wrapper sets `PONYTAIL_DEFAULT_MODE=ultra`, so no separate Ponytail config file is needed.
- Per-session `/ponytail` commands can still change the active mode.

### pi-caveman package

Caveman response style comes from the package-managed `pi-caveman` extension instead of a local skill and AGENTS.md rule.

- Pi loads `npm:pi-caveman` from `settings.json`; the package stays unpinned so `pi update --extensions` can update it.
- The package provides `/caveman` for session-level toggles and `/caveman config` for the default level and footer status setting.
- User-level `~/.pi/agent/caveman.json` sets `defaultLevel` to `ultra`; omitted fields use package defaults.

### pi-subagents package

Builtin subagents share one Sol model while package definitions control role-specific thinking and behavior.

- Pi loads `npm:pi-subagents` from `settings.json`; the package stays unpinned for `pi update --extensions`.
- `subagents.defaultModel` selects `openai-codex/gpt-5.6-sol` for every builtin without model frontmatter.
- No `agentOverrides` or shared thinking override are configured; package runtime discovery and agent definitions stay authoritative.

## Skills and prompts

Repo-owned skills and prompt templates are symlinked to Pi's config directory by Home Manager.

- Local skills live under `skills/`; package-managed skills and commands stay in `settings.json`.
- GitHits' official guided skill uses its Pi setup's shared `~/.agents/skills/githits-mcp/` path. Home Manager links it directly from the locked `githits-cli` source, so `nix:update` refreshes it.
- Home Manager activation reads `api/uidotsh` from pass and downloads every skill returned by ui.sh's authenticated API into `~/.agents/skills/`. New catalog entries install on the next apply.
- Prompt templates live under `prompts/` and are symlinked to `~/.pi/agent/prompts/`.
- Other external skills installed outside this repo remain user-level state.

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
