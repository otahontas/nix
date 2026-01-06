---
name: block-local-git-config
enabled: true
event: bash
pattern: git\s+config\s+(user\.name|user\.email|commit\.gpgsign)
action: block
---

🚫 **Local git config modification blocked**

You're attempting to modify git configuration locally.

**From your CLAUDE.md:**
> Git author/email/signing is configured globally - never set these locally per-repo

**What was blocked:**
- `git config user.name`
- `git config user.email`
- `git config commit.gpgsign`

**Why this matters:**
- Your git identity is configured globally
- Local overrides can cause commits to appear unverified
- Maintains consistency across all repositories

**If you need to change git settings:**
Use global config: `git config --global user.name "Your Name"`
