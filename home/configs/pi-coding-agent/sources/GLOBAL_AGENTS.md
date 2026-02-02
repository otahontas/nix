## Tools

- Always use `trash` instead of `rm` for file deletion
- Always use `brave-search` skill for web searches
- Always read `AGENTS.md` file

## Writing

- Use sentence case: "Next steps" not "Next Steps", "Plan overview" not "Plan Overview"
- Sacrifice grammar over being concise unless specifically asked to write clearly
- When ask to write text for humans use skill "writing-clearly-and-concisely"
- Prefer bullet points over paragraphs

## Coding specific guidelines:

- KISS, YAGNI - prefer duplication over wrong abstraction
- Prefer unix tools for single task scripts
- Use project scripts (just, package.json, Makefile, mise, uv, cargo.toml) for linting/formatting, not global tools
- Node/Deno/Bun: prefer package.json scripts, then node_modules/.bin/, over npx/bunx
- Always use lockfiles (npm ci, yarn install --frozen-lockfile)
- Only fix what's asked - no bonus improvements, refactoring, or extra comments unless requested

## Multi-step task workflow:

- For complex tasks: write plan in markdown file first. Use your judgment to determine if a task is "complex": if it involves multiple steps, file modifications, or research, it's better to plan first.
- Always clarify users intention unless request is completely clear
- If uncertain, say so immediately - don't guess what to implement
- Work incrementally:
  1. complete step
  2. explicitly run verification commands (e.g., build, lint, test).
  3. if verification passes, commit and mark step as done. If not, fix and verify. Only commit when a step is fully working.
- Don't create plans/markdown for simple single-step tasks

## Local development scripts:

- Use `.local_scripts/` for temporary verification scripts that shouldn't be committed
- Examples: version update checks, one-off validation scripts, personal dev utilities
- Scripts can be messy and repo-specific
