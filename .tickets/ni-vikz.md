---
id: ni-vikz
status: open
deps: []
links: []
created: 2026-02-12T18:59:15Z
type: task
priority: 1
assignee: Otto Ahoniemi
tags: [research, agents, orchestration, evidence]
---

# Investigate evidence-based multi-agent team setups and orchestration adaptation

- Research state-of-the-art agent swarm and agent team architectures used in literature and production tooling.
- Focus on evidence: peer-reviewed papers, strong technical reports, benchmark results, and reproducible evaluations.
- Compare orchestration patterns: role-specialized agents, planner-executor-critic loops, debate/self-consistency teams, tool-specialized agents, and hierarchical manager-worker setups.
- Extract what actually improves outcomes: quality, reliability, latency, cost, and failure modes compared to strong single-agent baselines.
- Translate findings into a concrete setup proposal for your workflow and describe how to adapt your orchestration skill beyond one-shot, well-scoped tickets.

## Acceptance Criteria

- Deliver a written review with sources and citations for each claim.
- Include at least one comparison table of architectures, task types, evidence strength, and measured gains.
- Include explicit section on negative or mixed results and where multi-agent setups do not help.
- Propose a practical target design for your environment: agent roles, prompts/protocols, handoff format, stopping criteria, and quality gates.
- Define an evaluation plan with measurable metrics and A/B comparison against your current orchestration skill workflow.
- Define next implementation tickets needed to adapt the orchestration skill based on the findings.
