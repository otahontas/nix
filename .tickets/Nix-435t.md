---
id: Nix-435t
status: open
deps: []
links: []
created: 2026-04-05T18:17:56Z
type: task
priority: 1
assignee: Otto Ahoniemi
tags:
  - ready-for-development
---

# Investigate best local LLM for Mac hardware

Figure out the best local LLM model for this machine for use as a gatekeeper classifier in the stop-hook.

Steps:

1. Check machine specs: `sysctl -n machdep.cpu.brand_string`, `sysctl -n hw.memsize` (divide by 1073741824 for GB), `system_profiler SPHardwareDataType | grep -E 'Chip|Memory|Cores'`
2. Research current best small models for classification (sub-3B params ideal). Use web search (firecrawl_search) to find current recommendations for: "best small LLM for classification tasks 2025" and "Apple Silicon local LLM benchmark small models"
3. Evaluate runtime options. For each (ollama, llama.cpp, mlx), check:
   - Is it available in nixpkgs? `nix search nixpkgs <name>` or `devenv search <name>`
   - Does it support OpenAI-compatible HTTP API? (needed for pi-agent integration)
   - What's the inference overhead compared to bare metal?
4. Pick the best combination: most performant model + lowest overhead runtime + nix availability
5. Document findings as a note on this ticket
6. Refine the existing placeholder ticket Nix-2eoh using the ticket-creator skill's Mode 4 (refine). Fill in the specifics: chosen runtime, model name, nix package, models.json entry snippet, installation commands. Tag it ready-for-development.

Goal: find what to run locally so the gatekeeper call is free and sub-second.

IMPORTANT: This ticket MUST refine Nix-2eoh (not create a new ticket) with the investigation findings.

## Acceptance Criteria

1. Machine specs documented in a ticket note (chip model, RAM in GB, CPU/GPU cores)
2. At least 3 candidate models listed with: name, parameter count, and source URL
3. Runtime comparison written in ticket note with: nix package name (if available), HTTP API support (yes/no), overhead assessment
4. Clear recommendation stated in ticket note: model name + runtime + rationale
5. Recommendation considers: must be installable via nix, must expose OpenAI-compatible API for pi-agent
6. Nix-2eoh refined with specifics (runtime, model, nix package, models.json snippet) and tagged ready-for-development
