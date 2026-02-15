# Plan: deep mode for Pi

## Goal

Build a "deep mode" for Pi that uses GPT-5.2-Codex (via existing `openai-codex` OAuth subscription) with high reasoning effort and an autonomous, research-first system prompt. Modeled after Amp's deep mode.

## Current setup

- Default model: `openai-codex/gpt-5.2-codex` with `high` thinking
- OAuth providers: `anthropic`, `openai-codex`, `github-copilot`
- Extensions managed via nix home-manager auto-discovery in `extensions/`
- The `preset.ts` example from Pi shows how to do this with JSON config, but it requires installing the preset extension separately

## Approach: presets.json + preset extension

The preset extension (`preset.ts` from Pi examples) already solves this problem. It lets you define named presets that configure model, thinking level, tools, and system prompt — exactly what deep mode needs.

### Why presets over a custom extension?

- The preset extension already handles model switching, tool restriction, system prompt injection, status display, keyboard shortcuts, and state persistence
- A custom extension would duplicate all that logic
- Presets are declarative JSON — easy to tweak without code changes
- Can define multiple modes (deep, plan, rush) in one config file

## Steps

### 1. Install the preset extension

Copy `preset.ts` from Pi examples to `extensions/` and add to nix auto-discovery.

File: `extensions/preset.ts`

No modifications needed — the extension works as-is. It reads `~/.pi/agent/presets.json` (global) and `.pi/presets.json` (project-local).

### 2. Create presets.json with deep mode preset

File: `sources/presets.json` (symlinked to `~/.pi/agent/presets.json` via nix)

```json
{
  "deep": {
    "provider": "openai-codex",
    "model": "gpt-5.2-codex",
    "thinkingLevel": "xhigh",
    "instructions": "You are in DEEP MODE — an autonomous problem-solving mode.\n\nBehavior:\n- Read files extensively before making any changes. Move through the codebase for as long as needed.\n- Do NOT ask clarifying questions unless the problem is fundamentally ambiguous.\n- Do NOT check in with the user between steps. Work autonomously until done.\n- Research thoroughly: grep for related code, find patterns, read tests, understand the architecture.\n- Only start editing after you deeply understand the problem and its full context.\n- When you make changes, make them decisively and completely in one pass.\n- Verify your work: run tests, build commands, or linters after changes.\n\nYou are not a pair programmer. You are a senior engineer who goes off and solves problems alone. The user gave you a clear problem — solve it end-to-end."
  }
}
```

Notes:

- Uses `openai-codex` provider (ChatGPT OAuth, no API key needed)
- `xhigh` reasoning for maximum thinking depth
- No tool restriction — GPT-5.2-Codex benefits from having all tools available. Amp's "tuned tools" likely means they removed some tools that the model misuses, but we should start with full tools and restrict only if needed.
- The system prompt captures the core deep mode philosophy: read first, don't ask, work autonomously, verify

### 3. Wire presets.json into nix config

Add a symlink in `default.nix`:

```nix
".pi/agent/presets.json".source = ./sources/presets.json;
```

### 4. Verify

- Stage new files: `git add extensions/preset.ts sources/presets.json`
- Apply: `devenv tasks run home:apply`
- Test: `pi --preset deep` or `/preset deep` mid-session, or `Ctrl+Shift+U` to cycle

## Usage

- `pi --preset deep` — start a session in deep mode
- `/preset deep` — switch to deep mode mid-session
- `/preset` — show preset selector
- `Ctrl+Shift+U` — cycle through presets
- Status bar shows `preset:deep` when active

## Future improvements (not in scope)

- Add `plan` and `rush` presets
- Add a `pid` shell alias for `pi --preset deep`
- Restrict tools if GPT-5.2-Codex misuses certain ones (e.g., remove `write` to force `edit`)
- Tune the system prompt based on real usage
- Switch to `gpt-5.3-codex` when OpenAI enables API access
