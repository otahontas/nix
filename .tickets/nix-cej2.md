---
id: nix-cej2
status: open
deps: []
links: []
created: 2026-02-14T16:00:53Z
type: task
priority: 2
assignee: Otto Ahoniemi
tags: [pi-skills]
---

# Improve devenv skill

Two improvements needed:

1. Always use `prek` instead of `pre-commit` command
2. .envrc template should use the full form instead of just `use devenv`:

```bash
#!/usr/bin/env bash

export DIRENV_WARN_TIMEOUT=20s

eval "$(devenv direnvrc)"

use devenv
```
