---
name: block-rm-sensitive-dirs
enabled: true
event: bash
pattern: \brm\s+.*(\~\/\.gnupg|\.gnupg|~\/\.ssh|\.ssh|private-keys)
action: block
---

🛑 **Blocked: rm command targeting sensitive directories**

You attempted to delete files in `.gnupg`, `.ssh`, or `private-keys` directories.

**This is blocked because:**
- These directories contain irreplaceable cryptographic keys
- Deletion is permanent and cannot be undone
- You should NEVER delete these without explicit user instruction

**If deletion is actually needed:**
- Ask the user to run the command manually
- Or use `trash` to move files to trash instead
