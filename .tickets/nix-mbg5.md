---
id: nix-mbg5
status: closed
deps: []
links: []
created: 2026-02-12T19:06:58Z
type: task
priority: 2
assignee: Otto Ahoniemi
tags: [agents, automation, research]
---

# Investigate autonomous agent loops with subscription model budgets

Research how to maximize value from paid AI subscriptions (Anthropic, Google, Copilot, Codex) by running agents autonomously in loops.

## Design

## Goal

Leave agents crunching improvements for specific tasks with minimal human intervention.

## Key areas to investigate

- **Orchestrator-driven autonomous loops**: use pi's orchestrate skill (or similar) to spawn agents that pick up tickets, implement, and self-review
- **Session token budget management**: run models in a loop until session tokens are exhausted, then wait/sleep until the next session window resets and resume
- **Tiered model strategy**:
  - Expensive/better models (Claude Opus, Gemini Ultra, etc.) → planning, architecture, review
  - Cheaper models (Claude Haiku/Sonnet, Gemini Flash, Copilot, Codex) → implementation from well-written plans
- **Ticket-driven workflow**: agents pull from ticket queue, implement, verify, commit, close — humans review async
- **Plan quality**: plans written by higher-tier models should be detailed enough that cheaper models can't fail executing them

## Questions to answer

1. Which subscriptions offer session/token budgets and how do resets work?
2. Can we detect "budget exhausted" programmatically and sleep until reset?
3. What's the right orchestration layer — pi orchestrate, custom scripts, or something else?
4. How to structure plans so cheap models reliably succeed?
5. What guardrails prevent runaway loops (cost, bad commits, infinite retries)?

## Subscriptions to cover

- Anthropic (Max/Pro plan)
- Google (Gemini Advanced / AI Studio)
- GitHub Copilot (Business/Enterprise)
- OpenAI Codex

## Acceptance Criteria

- Document each subscription's token/session budget and reset schedule
- Prototype a script or orchestration config that runs an agent loop until tokens exhausted, then waits
- Demonstrate tiered planning (expensive model plans, cheap model executes) on a real task
- Write up findings and recommended setup

## Notes

**2026-02-12T19:08:35Z**

## Existing infra & sandboxing notes

- **Pi coding agent** already fetches model quotas — extend this for budget-aware loop control
- **Sandboxing options to investigate**:
  - NixOS virtual machines
  - Apple Containers (macOS native VMs — Docker should run inside)
  - Other sandboxing tools (firejail, bubblewrap, gVisor, etc.)
- Sandboxing is important for letting agents run autonomously without risking host system
