---
name: warn-conventional-commits
enabled: true
event: bash
pattern: 'git commit.*-m\s+[''"](?!(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([\w-]+\))?: )'
action: warn
---

⚠️ **Non-conventional commit message detected**

Your CLAUDE.md requires conventional commits format: `type(optional-scope): description`

**Valid types:**
feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert

**Examples:**
- ✅ `feat: add dark mode toggle`
- ✅ `fix(auth): handle expired tokens correctly`
- ✅ `docs: update API documentation`
- ❌ `added dark mode` (wrong format)
- ❌ `Fix: bug` (wrong case, wrong format)

**Rules:**
- Use imperative mood ("add" not "added")
- Keep title under 72 characters
- No period at end of title
