---
name: block-claude-attribution
enabled: true
event: bash
pattern: git commit[\s\S]*(🤖 Generated with|Co-Authored-By: Claude)
action: block
---

🚫 **Claude attribution detected in commit message**

Your commit message contains Claude Code attribution that you've explicitly requested to exclude.

**Detected pattern:**
- `🤖 Generated with [Claude Code]`
- `Co-Authored-By: Claude <noreply@anthropic.com>`

**From your CLAUDE.md:**
- "No claude code co-author"
- "No ai attribution"

**What to do:**
Remove the attribution lines from the commit message and try again.
