# Pi coding agent

Home Manager owns Pi CLI installation, global configuration, local extensions, skills, prompts, and MCP servers.

## Home Manager ownership

Tracked files under [[home/configs/pi-coding-agent]] are source of truth for global Pi state.

[[home/configs/pi-coding-agent/default.nix]] installs the wrapped Pi package and links local resources. [[home/configs/pi-coding-agent/settings.json]] owns package and startup model defaults; [[home/configs/pi-coding-agent/merge-settings.sh]] merges these with other Pi preferences. [[home/configs/pi-coding-agent/models.json]] owns model metadata overrides; [[home/configs/pi-coding-agent/mcp.json]] owns MCP server configuration.

`defaultTools: ["+codemode"]` keeps codemode available without MCP while preserving the inherited default tools.

[[home/configs/symlinks/default.nix]] links Pi's session directory to iCloud-backed `~/Documents/pi-coding-agent-sessions`. Changing that link requires Pi to be stopped and both stores verified.

[[home/configs/pi-coding-agent/settings.json|Startup defaults]] store provider and bare model ID separately and select the initial thinking effort without restricting model cycling. Subagents inherit the active parent model unless their own definitions or run options select another.

[[home/configs/pi-coding-agent/models.json|Model overrides]] leave context windows, provider service tiers, and supported thinking levels to Pi. No local priority/Fast tier is requested.

The OpenAI chat default requires `/login openai`; subscription image generation separately requires `/login openai-codex`. Built-in MCP reads [[home/configs/pi-coding-agent/mcp.json]].

Global AGENTS and system-prompt sources follow [[architecture#AGENTS.md pipeline]]. Root `.pi/` contains repository-only extensions and lat.md skill source.

[[home/configs/pi-coding-agent/sources/APPEND_SYSTEM.md]] prioritizes information needed to understand, decide, or act, while preserving necessary reasoning and clear grammar. It omits obvious caveats and mandatory closing summaries, retaining neutral tone, sentence-case headings, and no unsolicited time estimates.

## Wrapper behavior

The Pi wrapper loads API keys from pass, exposes wrapper-only tools, and sets process-level integration required by installed packages.

[[home/configs/pi-coding-agent/default.nix]] supplies Gemini, Context7, and GitHits credentials and exposes `lat.md`, Plannotator, Poppler, and `rtk`. It does not load or export LAT credentials.

Plannotator and Chrome DevTools MCP use `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome`, not a Nix browser. Plannotator does not select a Chrome profile.

Package-managed extensions update through `pi update --extensions`; image generation is version-pinned so its reviewed tool contract stays fixed.

## Local extensions

Home Manager extensions are global; [[.pi/extensions|root extensions]] apply only to this repository. [[tsconfig.json]] checks both sets against Pi's installed package types.

Model-calling extensions use `ctx.modelRegistry.complete()` so authentication, provider composition, model settings, and endpoint overrides match the active Pi session.

### Project lat extension

[[.pi/extensions/lat.ts]] exposes Lat's six navigation and validation tools, prompt reminder, and end-of-task checks using the upstream Pi template adapted to the installed Pi API.

[[.pi/extensions/lat.ts#run]] executes the configured command and prefix arguments without a shell, preserving queries as literal arguments and forwarding tool cancellation. [[.pi/extensions/lat.ts#tryRun]] retains upstream's empty-result fallback for navigation failures; `lat_check` returns validation failures as errors. [[.pi/extensions/lat.ts#collapsibleResult]] renders compact search and section previews.

`before_agent_start` requires search before file access and reminds agents to maintain meaningful current-state documentation rather than a journal. It resets the correction limit only for user-message runs; custom-message runs preserve that state.

`agent_before_settle` runs full validation and upstream's Git diff documentation-sync heuristic after successful runs and their recovery work. The heuristic requests review, not filler documentation. A failed check or sync warning requests at most one correction per prompt; the next successful boundary rechecks without an unbounded loop. Errors and aborts do not trigger corrections.

The installed Pi API requires its current package imports, keybinding IDs, tool result details, message rendering, and actionable settlement boundary instead of upstream's older `agent_end` follow-up API. [[.pi/extensions/post-edit-hook.ts]] separately runs project `prek` after successful writes.

#### Local search backend

Lat's bundled MiniLM model supports offline embeddings without an API key, inference server, or model download at search time.

This checkout uses Lat's native user-level local preference and local search index. The preference is keyed by the absolute vault path and is not transferred with a clone. `lat paths --config` reports the user config; `lat reindex --local` selects the local backend using upstream's normal workflow. No repository-specific backend wrapper or enforcement configuration is installed.

### starship widget extension

Starship renders above Pi's built-in footer and removes only its duplicate location row, leaving upstream footer status intact.

[[home/configs/pi-coding-agent/extensions/starship-widget.ts]] refreshes on `agent_settled` so retries, compaction, and queued continuations finish first; [[home/configs/pi-coding-agent/extensions/starship-widget.ts#patchFooterLocationLine]] owns the footer adjustment.

### stop-hook extension

Stop-hook asks the current session model whether another pass is needed after tool-using turns and stops after repeated gatekeeper failures.

[[home/configs/pi-coding-agent/extensions/stop-hook.ts#GATEKEEPER_PROMPT]] preserves requested scope, so investigation-only work reports findings instead of applying fixes. `agent_before_settle` waits for retries, compaction, and queued work before checking; errors and aborts are ignored.

Tool-use tracking resets for each non-extension input, so old transcript tools cannot trigger a nudge for a new tool-free prompt. One boundary message requests a continuation without inserting a synthetic user message or requiring another completion confirmation.

### search-sessions extension

Search-sessions reads a launchd-built BM25 index; session reads are restricted to JSONL files inside Pi's session directory.

[[home/configs/pi-coding-agent/scripts/build-session-index.sh|The indexer]] follows the session directory symlink and publishes rebuilt indexes with an atomic rename. [[home/configs/pi-coding-agent/extensions/search-sessions.ts#loadIndex]] checks the index modification time and refreshes cached entries and BM25 metadata when it changes.

[[home/configs/pi-coding-agent/extensions/search-sessions.ts#computeMeta]] counts document frequency once per term per session across title and content. [[home/configs/pi-coding-agent/extensions/search-sessions.ts#bm25Score]] uses token counts for length normalization and positive IDF to keep common terms searchable. [[home/configs/pi-coding-agent/extensions/search-sessions.ts#resolveSessionPath]] enforces the session-directory boundary.

### name-session extension

Name-session derives a short title from the first real prompt while preserving manual or restored names and ignoring extension-generated prompts.

Custom-message runs are ignored before changing prompt-origin tracking, so they cannot consume the next user prompt’s naming state.

[[home/configs/pi-coding-agent/extensions/name-session.ts#generateTitle]] requests minimal reasoning when supported, otherwise the active session's current effort. Generation is best effort and guarded against session switches so stale calls cannot rename another session.

### clone-cmd extension

[[home/configs/pi-coding-agent/extensions/clone-cmd.ts]] registers `/clone-cmd` to clone the current session leaf and copy a launch command without switching the active pane.

### notify extension

Notifications fire after non-aborted `agent_settled` events in interactive sessions and use sanitized session names with a fixed `done` body. Cancelled runs produce neither a notification nor BEL.

[[home/configs/pi-coding-agent/extensions/notify.ts#notify]] emits OSC 777 plus BEL so Ghostty owns visual and attention effects without transcript parsing or model calls.

Ghostty 1.3.1 answers an OSC 4 control query but not the OSC 7501 support query. Pi's program-status detection stays automatic; forcing reports cannot add missing terminal support.

## Package-managed behavior

Reusable behavior stays package-managed instead of being copied into local extensions.

[[home/configs/pi-coding-agent/settings.json]] owns subagents, Plannotator, RTK, web access, and the pinned image-generation package. Pi's built-in MCP reads [[home/configs/pi-coding-agent/mcp.json]]; pi-subagents runtime definitions remain authoritative.

Coding scope and KISS/YAGNI rules remain in [[home/configs/pi-coding-agent/sources/GLOBAL_AGENTS.md]]; response style comes from [[home/configs/pi-coding-agent/sources/APPEND_SYSTEM.md]].

The image-generation package supplies `image_generate`. Its fixed `codex-subscription` / `gpt-image-2` route uses separate Codex OAuth without changing the OpenAI chat default or silently falling back to paid API billing. It calls the Codex image endpoints directly and does not require the standalone Codex CLI. Reference edits, size, quality, and native transparency are exposed; actual backend output needs workflow testing.

## Verification

TypeScript checks validate root and Home Manager Pi extensions against Pi's installed package types.

Run `devenv shell -- tsc -p tsconfig.json --noEmit --pretty false`. This checks types, not runtime behavior.

Offline installation checks cover the pinned launcher, global skill discovery, image tool registration and schema, and unchanged chat defaults without model or image requests. Image generation is tested in frontend projects after Codex login.

Temporary model benchmarks stay in `.local_scripts/` without changing startup settings. Use identical tasks and exact-match scoring across supported efforts; record elapsed request time and returned `service_tier`. Keep errors and 240-second cutoffs in elapsed-time and quality averages, with zero quality for missing answers; report completion rate separately. ChatGPT OAuth may return `default` for `priority` and reject `fast`.

Paired speed checks hold model, effort, and prompt fixed, balance request order, run sequentially, and exclude warm-ups. Explicit per-request `samplingParams.service_tier` keeps the compared tiers independent of model configuration. Record text throughput, reasoning/output token counts, cache hits, and response tier separately; a tier label alone does not establish a latency benefit or its absence.

## Skills and prompts

[[home/configs/pi-coding-agent/default.nix]] links repo-owned skills and prompts into Pi's global config.

Repository Lat guidance lives in [[AGENTS.md]] and [[.pi/skills/lat-md/SKILL.md]], refreshed from upstream's instruction and authoring templates. Project-specific knowledge belongs in `lat.md/`, not generated guidance. The instruction template's stale hosted-key requirement is corrected to reflect upstream's offline local backend.

[[home/configs/pi-coding-agent/prompts/merge-worktree.md|/merge-worktree]] infers its non-main target from context, commits all changes, rebases onto local `main`, fast-forwards `main`, then safely removes the merged worktree and branch without remote operations. [[home/configs/pi-coding-agent/skills/git-worktrees/SKILL.md|The worktree skill]] covers local branches only.

GitHits' guided skill comes from its locked source. [[home/configs/pi-coding-agent/skills/explain-diff-html/SKILL.md|Explain Diff]] generates self-contained HTML walkthroughs for code changes. [[home/configs/pi-coding-agent/prompts/plannotator-loop.md|/plannotator-loop]] revises one file in the current Pi context until approval. Skills installed outside this repo remain user state.

[[home/configs/pi-coding-agent/default.nix|Impeccable and its required native engine]] are Nix-pinned. Home Manager links the global Pi skill; `IMPECCABLE_BIN` selects the store binary without first-use downloads. Invoke `/skill:impeccable`; automatic edit hooks are not installed. Its native image workflow can use `image_generate`, with prompt metadata and sidecars handled by the skill.
