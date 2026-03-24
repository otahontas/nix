# Pi 0.60–0.62 changelog review

Reviewed changelogs for pi versions 0.60.0, 0.61.0, 0.61.1, and 0.62.0 against all extensions and skills in this repo.

## Broken: `guardrails.ts` text guards

The `agent_response` event no longer exists in pi. It is absent from both type definitions and runtime code — `pi.on("agent_response", ...)` registers a handler that never fires.

Two guards depend on this event and are dead:

- `blockCorporateBuzzwords`
- `blockTitleCaseHeaders`

The closest replacement, `message_end`, cannot block responses (its handler has no result type). There is no migration path that preserves blocking behavior.

**Recommendation:** Remove both guards. They have been silently broken without anyone noticing, which suggests low practical value. The bash-targeting guards (`blockLocalGitConfig`, `blockNonConventionalCommits`, `blockNpxBunx`, `blockRmCommand`, `blockNonStandardWorktreePath`, `blockSecretTools`) use the `tool_call` event and work correctly.

## Free rendering improvement: `hashline-edit.ts`

Starting in 0.62.0, built-in tool renderer inheritance works per slot. Extensions that override a built-in tool without defining `renderCall` or `renderResult` now inherit the built-in renderers (syntax highlighting, diffs, etc.) automatically.

The hashline-edit extension omits both renderers, so it benefits from this change with no code modifications needed.

## Optional: typed event handler returns

Pi 0.61.1 added `ToolCallEventResult` and `ToolResultEventResult` type exports. Two extensions could use these for explicit return typing:

- `guardrails.ts` — guard functions return `{ block, reason }` which matches `ToolCallEventResult`
- `claude-code-hooks.ts` — `tool_call` and `tool_result` handlers return untyped objects

This is a developer ergonomics improvement with no runtime effect.

## No changes needed

- `custom-footer.ts` — no affected APIs
- `model-quota.ts` — no affected APIs
- `notify.ts` — no affected APIs
- `rainbow-editor.ts` — `CustomEditor` unchanged
- `learn.ts` — no affected APIs
- `hashline-edit.ts` — `createReadTool` still exported, works as-is
- All skills — no API changes affect SKILL.md files
- `settings.json` — no relevant config changes
