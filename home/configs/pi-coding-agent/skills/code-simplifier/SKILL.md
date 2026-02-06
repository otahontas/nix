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
2. **Analyze** — look for opportunities to improve clarity and consistency
3. **Apply refinements** — make changes that preserve functionality
4. **Verify** — run existing tests/checks if available
5. **Summarize** — document only significant changes

## Refinement rules

### Preserve functionality

- Never change what the code does, only how it does it
- All original features, outputs, and behaviors must remain intact

### Follow project standards

- Read AGENTS.md for project conventions
- Follow established import patterns, naming conventions, error handling patterns
- Match existing code style in the project

### Enhance clarity

- Reduce unnecessary complexity and nesting
- Eliminate redundant code and wrong abstractions
- Improve variable and function names where unclear
- Consolidate related logic
- Remove comments that describe obvious code
- Avoid nested ternary operators — prefer switch/if-else for multiple conditions
- Choose clarity over brevity — explicit code beats overly compact code

### Maintain balance — do not

- Reduce code clarity or maintainability
- Create overly clever solutions hard to understand
- Combine too many concerns into single functions
- Remove helpful abstractions that improve organization
- Prioritize "fewer lines" over readability (nested ternaries, dense one-liners)
- Make code harder to debug or extend

## Output

For each change, briefly explain what was simplified and why. Group by file if multiple files are affected.
