---
name: warn-npx-bunx
enabled: true
event: bash
pattern: '\b(npx|bunx)\s+'
action: warn
---

⚠️ **npx/bunx usage detected**

Your CLAUDE.md says: "Node/Deno/Bun: use package.json scripts, then node_modules/.bin/, avoid npx/bunx"

**Preferred alternatives:**
1. Check if there's a package.json script for this
2. Use `./node_modules/.bin/<command>` directly
3. Add a script to package.json if it's a common operation

**Why avoid npx/bunx:**
- Slower (downloads packages each time if not cached)
- Version inconsistency between runs
- package.json scripts are explicit and documented
