---
id: Nix-4bkk
status: in_progress
deps: [Nix-t9cs]
links: []
created: 2026-04-05T18:51:54Z
type: task
priority: 1
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Investigate best cheap model on z.ai API for gatekeeper classification

Research which model on the z.ai API (https://api.z.ai/api/coding/paas/v4) is best suited for the stop-hook gatekeeper task — a simple yes/no classification of whether an agent response warrants a self-review nudge.

Requirements for the gatekeeper model: cheap (low cost per call), fast latency (< 2s ideally), good enough for simple classification (not complex reasoning), available on the z.ai API.

Steps:

1. Query the z.ai API for available models. Use the existing auth from ~/.pi/agent/models.json (provider 'zai', apiKey env var 'ZAI_API_KEY'). Try: curl -H "Authorization: Bearer $ZAI_API_KEY" https://api.z.ai/api/coding/paas/v4/models — adjust endpoint if needed based on the API response or by searching z.ai docs
2. From the model list, identify the cheapest/smallest model suitable for classification. Prefer models like glm-4.7, glm-4, or similar small variants over glm-5.1
3. Test the model with a simple classification prompt using curl: curl -X POST https://api.z.ai/api/coding/paas/v4/chat/completions -H "Authorization: Bearer $ZAI_API_KEY" -H "Content-Type: application/json" -d '{"model": "MODEL_ID", "messages": [{"role": "user", "content": "Answer YES or NO: should an AI agent self-review after helping with a bike purchase question?"}]}'
4. Write findings as a note on this ticket
5. Refine the existing placeholder ticket Nix-nt4b using the ticket-creator skill's Mode 4 (refine). Fill in the specifics discovered during this investigation. Then close this ticket.

Current models.json entry for reference (glm-5.1 on zai provider). File: ~/.pi/agent/models.json

IMPORTANT: This ticket MUST refine Nix-nt4b (not create a new ticket) with: the exact model ID to add, any API differences (endpoint, auth, etc.) from glm-5.1, suggested models.json entry (complete JSON snippet), verification steps (curl command to test, pi startup check). Tag it ready-for-development.

## Acceptance Criteria

1. curl to z.ai API model listing returns available models, output saved as ticket note
2. One model selected and documented with: model ID, context window, max tokens
3. curl test with the selected model returns a valid chat completion response
4. Nix-nt4b refined with exact model ID and complete models.json entry snippet using ticket-creator Mode 4
5. Findings added as note on this ticket

## Notes

**2026-04-05T19:56:19Z**

## Investigation findings

### Available models (from /models endpoint)

glm-4.5, glm-4.5-air, glm-4.6, glm-4.7, glm-5, glm-5-turbo, glm-5.1

Also in pricing docs but NOT in /models listing: glm-4.7-flash (free, rate-limited), glm-4.5-flash (free, rate-limited), glm-4.7-flashx ($0.07/M input, insufficient balance error)

### Recommended model: glm-4.5-air

**Why:** cheapest model available on this API tier, fastest latency, MoE architecture (12B active params)

| Property       | Value                              |
| -------------- | ---------------------------------- |
| Model ID       | glm-4.5-air                        |
| Context window | 128K tokens                        |
| Max output     | 32K tokens                         |
| Input price    | $0.20/M tokens                     |
| Output price   | $1.10/M tokens                     |
| Architecture   | MoE: 106B total, 12B active params |
| Reasoning      | Yes (cannot be disabled)           |
| License        | MIT                                |

### Latency test results

| Model           | Latency   | Total tokens |
| --------------- | --------- | ------------ |
| **glm-4.5-air** | **~4.2s** | **~300**     |
| glm-4.7         | ~6.8s     | ~313         |
| glm-5-turbo     | ~6.2s     | ~240         |
| glm-4.6         | ~9.4s     | ~474         |
| glm-4.5         | ~12.9s    | ~542         |

### Cost per gatekeeper call

~50 input tokens + ~300 reasoning/output tokens = ~$0.00035/call (~35 cents per 1000 calls)

### Caveats

- All z.ai models have built-in reasoning that cannot be disabled via API parameters (tested reasoning_effort:none, max_tokens, max_completion_tokens)
- Latency ~4s exceeds the <2s ideal but acceptable for a stop-hook gatekeeper
- GLM-4.7-Flash is free but rate-limited — not reliable for production use
- Reasoning tokens count against max_tokens limit (setting max_tokens=10 cuts off reasoning and yields empty content)

### Suggested models.json entry

```json
{
  "id": "glm-4.5-air",
  "reasoning": true,
  "input": ["text"],
  "contextWindow": 131072,
  "maxTokens": 32768
}
```

### Verification curl command

```bash
curl -s -X POST https://api.z.ai/api/coding/paas/v4/chat/completions   -H "Authorization: Bearer $ZAI_API_KEY"   -H "Content-Type: application/json"   -d '{"model": "glm-4.5-air", "messages": [{"role": "user", "content": "Answer YES or NO: does 2+2=4?"}]}'
```
