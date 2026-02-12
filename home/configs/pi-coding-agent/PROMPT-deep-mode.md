Implement deep mode for Pi using the preset extension. Follow PLAN-deep-mode.md exactly.

Steps:

1. Copy the preset extension from Pi examples to `extensions/preset.ts`. Find it at the pi-coding-agent package examples directory (look for `preset.ts`). Copy as-is, no modifications.

2. Create `sources/presets.json`:

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

3. Add symlink to `default.nix` in the `home.file` attrset:

```nix
".pi/agent/presets.json".source = ./sources/presets.json;
```

4. Stage new files, apply, and verify:
   - `git add extensions/preset.ts sources/presets.json`
   - `devenv tasks run home:apply`
   - Confirm `~/.pi/agent/presets.json` and `~/.pi/agent/extensions/preset.ts` exist

5. Delete PLAN-deep-mode.md and this prompt file after done.
