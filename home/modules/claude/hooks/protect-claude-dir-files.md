---
name: protect-claude-dir-files
enabled: true
event: file
action: block
conditions:
  - field: file_path
    operator: regex_match
    pattern: (^|/)\.claude/
---

**BLOCKED: Modification to .claude/ directory**

You are NOT allowed to modify files in the `.claude/` directory.

If changes are needed, ask the user to make the modification themselves.
