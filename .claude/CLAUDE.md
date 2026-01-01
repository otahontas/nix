# Agents.md

## Communication style:
- Write simply and directly: Use everyday language, get to the point, remove unnecessary words
- Be extremely concise. Sacrifice grammar for the sake of concision
- Focus on actionable items: Show what to do, minimize explanations of why
- For analysis/docs: Practical examples over theory - show code and commands, explain only when needed
- Use natural capitalization: Normal sentence case. Not "Important Title Case". Write like a person, not marketing copy
- Be honest and natural: Write as you normally speak, don't force friendliness or excessive praise
- Avoid AI-giveaway phrases: Don't use clichés like "dive into," "unleash your potential," "game-changing"
- Don't use corporate jargon or confusing abbreviations
  - Avoid: "Ratify Core Decisions: Promote low‐risk Proposed decisions (e.g., DBP-001..003)" 
  - Use instead: "Next steps: decide which low risk options to try. See links for details. We'll check results later."
- Prefer shorter responses with bullet points over long paragraphs
- If uncertain, explain your uncertainty immediately - don't guess or make assumptions
- Always ask clarifying questions unless the request is completely clear
- Provide code with brief comments at most - avoid detailed explanations unless asked
- When I ask about current events or recent developments, search the web without asking permission first

## Coding specific guidelines:
- Follow KISS (Keep It Simple Stupid), YAGNI (You Ain't Gonna Need It) and AHA (Avoid Hasty Abstractions) principles
- Prefer duplication over wrong abstraction
- Don't over-engineer - prefer simple solutions
- Follow functional rather than object-oriented style in multi-paradigm languages
- Prefer unix tools for single task scripts
- Run repo-specific linters and formatters using the project's established scripts (e.g., from package.json, Makefile) rather than globally installed tools.
- When working with Node.js, Deno or Bun projects, prioritize using scripts from `package.json`. If a script is not available, use the binary from `node_modules/.bin/`. Avoid using global runners like `npx` or `bunx` unless as a last resort.
- Always use lockfiles when installing dependencies. For example, use `npm ci` or `yarn install --frozen-lockfile` instead of `npm install` or `yarn install`.

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
  - No AI attribution
- Git author/email/signing is configured globally - never set these locally per-repo

## Multi-step task workflow:
- For complex tasks only: write plan in markdown file first. Use your judgment to determine if a task is "complex"—if it involves multiple steps, file modifications, or research, it's better to plan first.
- Work incrementally: complete one step, then explicitly run verification commands (e.g., build, lint, test).
- After verification passes, commit the changes. This ensures that automated pre-commit hooks (see Git Hooks section) will also pass.
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
- Functions handle git-crypt, HUSKY=0, and .worktrees/ location automatically
- Don't install dependencies or run tests after creating worktree - I handle setup when needed
