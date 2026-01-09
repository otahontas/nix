## Communication style:

- Headers: always use sentence case ("Next steps" not "Next Steps", "Plan overview" not "Plan Overview")
- Write simply and directly - everyday language, get to the point, remove unnecessary words
- Break complex explanations into one issue at a time
- Show what to do, not why - practical examples over theory
- Write like a person: no corporate jargon, no AI phrases
- Prefer bullet points over paragraphs
- If uncertain, say so immediately - don't guess
- Always clarify unless request is completely clear
- For docs/READMEs: personal voice ("I built this because...") not corporate ("This provides...")
- Web search current events without asking first

## Coding specific guidelines:

- KISS, YAGNI - prefer duplication over wrong abstraction, keep it simple
- Prefer unix tools for single task scripts
- Use project scripts (package.json, Makefile, mise, uv, cargo.toml) for linting/formatting, not global tools
- Node/Deno/Bun: prefer package.json scripts, then node_modules/.bin/, over npx/bunx
- Always use lockfiles (npm ci, yarn install --frozen-lockfile)
- Only fix what's asked - no bonus improvements, refactoring, or extra comments unless requested

## Git commit conventions:

- Always use conventional commits format: `type(optional-scope): description`
- Valid types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
- Examples:
  - feat: add dark mode toggle
  - fix(auth): handle expired tokens correctly
  - docs: update API documentation
- When creating commits:
  - Use imperative mood ("add" not "added")
  - Keep title under 72 characters
  - No period at end of title
  - No AI attribution (no co-author, no "Generated with Claude")

## Multi-step task workflow:

- For complex tasks only: write plan in markdown file first. Use your judgment to determine if a task is "complex"—if it involves multiple steps, file modifications, or research, it's better to plan first.
- Work incrementally: complete one step, then explicitly run verification commands (e.g., build, lint, test).
- After verification passes, commit the changes. This ensures that automated pre-commit hooks will also pass.
- Only commit when a step is fully working.
- Don't create plans/markdown for simple single-step tasks

## Local development scripts:

- Use `.local_scripts/` for temporary verification scripts that shouldn't be committed
- Examples: version update checks, one-off validation scripts, personal dev utilities
- Scripts can be messy and repo-specific
- Never add .local_scripts/ to .gitignore file in project. Always rely on the fact that .local_scripts/ is ignored globally.

## Git worktrees:

- Always use shell functions: `git-worktree-new`, `git-worktree-pr`, `git-worktree-prune`
- Never use manual `git worktree add` commands
- Don't install dependencies or run tests after creating worktree - I handle setup when needed
