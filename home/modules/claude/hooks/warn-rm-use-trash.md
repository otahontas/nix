---
name: warn-rm-use-trash
enabled: true
event: bash
pattern: \brm\s+-[rf]
action: warn
---

⚠️ **rm -rf detected - consider using trash instead**

You're about to permanently delete files. Consider:

1. **Use `trash` instead** - moves to Trash, recoverable
2. **Ask user first** - especially for dotfiles or config directories
3. **Be specific** - avoid broad patterns like `*.key` or wildcards in home directories

**Never use rm -rf on:**
- `~/.gnupg`, `~/.ssh`, or any directory with private keys
- Any dotfile directory without explicit user confirmation
