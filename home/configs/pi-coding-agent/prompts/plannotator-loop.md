---
description: Review and revise a file in Plannotator until approved
argument-hint: "<file>"
---

# Plannotator file review loop

Review `$1` in a loop using this Pi session and its existing context.

1. Run `plannotator annotate "$1" --gate` with a long or disabled timeout.
2. If annotations are returned, apply all requested changes to `$1`, then run the same command again.
3. Repeat until Plannotator returns `The user approved.`
4. If the session closes without feedback or the command fails, stop and report why.

Do not launch another agent or use Plannotator's Browser Agent TUI.
