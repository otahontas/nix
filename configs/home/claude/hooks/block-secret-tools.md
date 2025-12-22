---
name: block-secret-tools
enabled: true
event: bash
pattern: (^|\s)(pass|gpg\s+(--decrypt|-d|--export-secret-keys|--export-secret-subkeys|--list-secret-keys|-K))(\s|$)
action: block
---

🔒 **Secret management command blocked**

You've configured Claude Code to never run commands that could expose secrets:
- `pass` (password-store)
- `gpg --decrypt` / `gpg -d` (GPG decryption)
- `gpg --export-secret-keys` / `gpg --export-secret-subkeys` (private key export)
- `gpg --list-secret-keys` / `gpg -K` (secret key listing)

**Why this is blocked:**
Running these commands would expose your secrets in the conversation context, which is a security risk.

**What to do instead:**
- Run these commands manually in your terminal
- Use launchd agents in your nix-darwin config to generate config files from secrets (see CLAUDE.md pattern)
- Create wrapper scripts that use secrets without exposing them to Claude

If you need to temporarily disable this rule, set `enabled: false` in `.claude/hookify.block-secret-tools.local.md`.
