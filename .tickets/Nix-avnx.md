---
id: Nix-avnx
status: closed
deps: []
links: []
created: 2026-04-05T18:52:47Z
type: task
priority: 1
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Investigate best local LLM for Mac hardware

Figure out the best local LLM model for this machine for use as a gatekeeper classifier in the stop-hook.

Steps:

1. Check machine specs: sysctl -n machdep.cpu.brand_string, sysctl -n hw.memsize (divide by 1073741824 for GB), system_profiler SPHardwareDataType | grep -E 'Chip|Memory|Cores'
2. Research current best small models for classification (sub-3B params ideal). Use web search (firecrawl_search) to find current recommendations for: best small LLM for classification tasks 2025 and Apple Silicon local LLM benchmark small models
3. Evaluate runtime options. For each (ollama, llama.cpp, mlx), check: is it available in nixpkgs? (nix search nixpkgs <name> or devenv search <name>), does it support OpenAI-compatible HTTP API? (needed for pi-agent integration), what's the inference overhead compared to bare metal?
4. Pick the best combination: most performant model + lowest overhead runtime + nix availability
5. Document findings as a note on this ticket
6. Refine the existing placeholder ticket Nix-2eoh (will be created next) using the ticket-creator skill's Mode 4 (refine). Fill in the specifics: chosen runtime, model name, nix package, models.json entry snippet, installation commands. Tag it ready-for-development.

IMPORTANT: This ticket MUST refine the placeholder ticket (not create a new ticket) with the investigation findings.

## Acceptance Criteria

1. Machine specs documented in a ticket note (chip model, RAM in GB, CPU/GPU cores)
2. At least 3 candidate models listed with: name, parameter count, and source URL
3. Runtime comparison written in ticket note with: nix package name (if available), HTTP API support (yes/no), overhead assessment
4. Clear recommendation stated in ticket note: model name + runtime + rationale
5. Recommendation considers: must be installable via nix, must expose OpenAI-compatible API for pi-agent
6. Placeholder ticket refined with specifics (runtime, model, nix package, models.json snippet) and tagged ready-for-development

## Notes

**2026-04-05T19:33:25Z**

Machine specs: Apple M1 Pro, 16 GB unified RAM, 10 cores (8 performance + 2 efficiency)

**2026-04-05T19:33:34Z**

Candidate models (sub-3B for classification):

1. Qwen3.5-0.8B — 0.8B params, Apache 2.0, multimodal, 262K context
   Source: https://huggingface.co/Qwen/Qwen3.5-0.8B
   Best small Qwen variant, good instruction-following at minimal size

2. Qwen2.5-0.5B-Instruct — 0.5B params, Apache 2.0, 128K context
   Source: https://huggingface.co/Qwen/Qwen2.5-0.5B-Instruct
   Even smaller fallback, solid for zero-shot classification

3. Phi-4-mini-instruct — 3.8B params, MIT license, 128K context
   Source: https://huggingface.co/microsoft/Phi-4-mini-instruct
   Strong reasoning but too large for a lightweight gatekeeper on 16GB

**2026-04-05T19:33:44Z**

Runtime comparison:

| Runtime      | Nix package                     | OpenAI API | Overhead |
| ------------ | ------------------------------- | ---------- | -------- |
| Ollama       | ollama (aarch64-darwin: yes)    | Yes        | Medium   |
| llama.cpp    | llama-cpp (aarch64-darwin: yes) | Yes        | Low      |
| MLX (mlx-lm) | python313Packages.mlx-lm (yes)  | Partial    | Low      |

Key finding: Ollama 0.19 now uses MLX internally on Apple Silicon (announced March 30, 2026). This gives native MLX performance through Ollama's mature OpenAI-compatible HTTP API. On M1 Max 64GB, users report ~23 tok/s decode with MLX vs ~3 tok/s with old llama.cpp backend (7x speedup). M1 Pro 16GB will see similar relative gains.

All three are available in nixpkgs for aarch64-darwin.

**2026-04-05T19:33:52Z**

Recommendation: Ollama + Qwen3.5-0.8B (or Qwen2.5-0.5B fallback)

Rationale:

- Ollama: best developer experience, native OpenAI-compatible API at /v1/chat/completions, now uses MLX on Apple Silicon for top performance, available in nixpkgs
- Qwen3.5-0.8B: latest small model from Qwen family which dominates classification benchmarks, ~1-2GB VRAM quantized, fits easily on 16GB M1 Pro alongside other apps
- For binary classification (nudge/no-nudge), sub-1B model is more than sufficient — larger models waste resources
- pi-agent integration: point OLLAMA_HOST to local endpoint, add model to models.json as openai-compatible provider

Install: nix package 'ollama', then 'ollama pull qwen3.5:0.8b'
The model tag in ollama library is 'qwen3.5:0.8b'

**2026-04-05T19:35:27Z**

Completed. Machine specs documented, 3 candidate models evaluated, 3 runtimes compared, recommendation made (Ollama + Qwen3.5-0.8B). Placeholder ticket Nix-ra0y refined with full specifics and tagged ready-for-development.
