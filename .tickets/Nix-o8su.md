---
id: Nix-o8su
status: open
deps: [Nix-5oy7]
links: []
created: 2026-04-05T18:17:08Z
type: task
priority: 1
assignee: Otto Ahoniemi
tags:
  - ready-for-development
---

# Investigate best cheap model on z.ai API for gatekeeper classification

Research which model on the z.ai API (https://api.z.ai/api/coding/paas/v4) is best suited for the stop-hook gatekeeper task — a simple yes/no classification of whether an agent response warrants a self-review nudge.

Requirements for the gatekeeper model:

- Cheap (low cost per call)
- Fast latency (< 2s ideally)
- Good enough for simple classification (not complex reasoning)
- Available on the z.ai API

Steps:

1. Query the z.ai API for available models. Use the existing auth from ~/.pi/agent/models.json (provider 'zai', apiKey env var 'ZAI_API_KEY'). Try: `curl -H "Authorization: Bearer $ZAI_API_KEY" https://api.z.ai/api/coding/paas/v4/models` — adjust endpoint if needed based on the API response or by searching z.ai docs
2. From the model list, identify the cheapest/smallest model suitable for classification. Prefer models like glm-4.7, glm-4, or similar small variants over glm-5.1
3. Test the model with a simple classification prompt using curl:

```bash
curl -X POST https://api.z.ai/api/coding/paas/v4/chat/completions \
  -H "Authorization: Bearer $ZAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model": "MODEL_ID", "messages": [{"role": "user", "content": "Answer YES or NO: should an AI agent self-review after helping with a bike purchase question?"}]}'
```

4. Write findings as a note on this ticket
5. Refine the existing placeholder ticket Nix-nt4b using the ticket-creator skill's Mode 4 (refine). Fill in the specifics discovered during this investigation. Then close this ticket.

Current models.json entry for reference (glm-5.1 on zai provider):
File: ~/.pi/agent/models.json

IMPORTANT: This ticket MUST refine Nix-nt4b (not create a new ticket) with:

- The exact model ID to add
- Any API differences (endpoint, auth, etc.) from glm-5.1
- Suggested models.json entry (complete JSON snippet)
- Verification steps (curl command to test, pi startup check)
- Tag it ready-for-development

## Acceptance Criteria

1. `curl` to z.ai API model listing returns available models, output saved as ticket note
2. One model selected and documented with: model ID, context window, max tokens
3. `curl` test with the selected model returns a valid chat completion response
4. Follow-up ticket created with exact model ID and complete models.json entry snippet
5. Findings added as note on this ticket
