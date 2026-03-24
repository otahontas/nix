---
name: code-simplifier
description: Simplifies and refines code for clarity, consistency, and maintainability while preserving all functionality. Focuses on recently modified code unless instructed otherwise. Use when asked to simplify, clean up, or refine code.
---

# Code simplifier

Simplify and refine code for clarity, consistency, and maintainability while preserving exact functionality.

## Scope

- Focus on recently modified code (check `git diff --name-only` if unsure)
- If the user specifies files or broader scope, use that instead
- Do not touch unrelated code

## Process

1. **Identify target code** — find recently modified sections or user-specified files
2. **Apply refinements** — make changes that preserve functionality
3. **Verify** — run existing tests/checks if available
4. **Summarize** — document only significant changes

## Rules

- Read AGENTS.md and match existing project conventions
- Never change what the code does, only how it does it
- Reduce unnecessary complexity, nesting, and redundant code
- Improve unclear variable and function names
- Remove comments that describe obvious code
- Choose clarity over brevity — explicit code beats overly compact code
- Don't create overly clever solutions or combine too many concerns into single functions

## Output

For each change, briefly explain what was simplified and why. Group by file if multiple files are affected.
