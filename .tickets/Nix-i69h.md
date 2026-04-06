---
id: Nix-i69h
status: closed
deps: [Nix-4bkk]
links: []
created: 2026-04-05T18:52:05Z
type: feature
priority: 1
assignee: Otto Ahoniemi
tags: [ready-for-development]
---

# Add glm-4.5-air gatekeeper model to pi-agent models.json

Add `glm-4.5-air` (investigated in Nix-4bkk) to pi-agent's model registry as the cheap gatekeeper model. This is the cheapest model available on the z.ai API that works reliably — $0.20/M input, $1.10/M output, ~4s latency, 128K context, 32K max output.

## What to do

Add the following entry to the `zai.models` array in `~/.pi/agent/models.json`:

```json
{
  "id": "glm-4.5-air",
  "reasoning": true,
  "input": ["text"],
  "contextWindow": 131072,
  "maxTokens": 32768
}
```

Insert it before the existing glm-5.1 entry so the file looks like:

```json
{
  "providers": {
    "zai": {
      "baseUrl": "https://api.z.ai/api/coding/paas/v4",
      "apiKey": "ZAI_API_KEY",
      "api": "openai-completions",
      "models": [
        {
          "id": "glm-4.5-air",
          "reasoning": true,
          "input": ["text"],
          "contextWindow": 131072,
          "maxTokens": 32768
        },
        {
          "id": "glm-5.1",
          "reasoning": true,
          "input": ["text"],
          "contextWindow": 204800,
          "maxTokens": 131072
        }
      ]
    }
  }
}
```

No other API changes needed — same endpoint, same auth, same API format as glm-5.1.

File: `~/.pi/agent/models.json`

## Acceptance Criteria

1. `glm-4.5-air` entry added to models.json under the existing `zai` provider (no new provider needed)
2. Valid JSON — `cat ~/.pi/agent/models.json | python3 -m json.tool` succeeds
3. API call works: `curl -s -X POST https://api.z.ai/api/coding/paas/v4/chat/completions -H "Authorization: Bearer $ZAI_API_KEY" -H "Content-Type: application/json" -d '{"model": "glm-4.5-air", "messages": [{"role": "user", "content": "Answer YES or NO: does 2+2=4?"}]}'` returns a valid chat completion with `"model": "glm-4.5-air"`
4. Model appears in pi model selector (`/model`)
5. Sending a simple prompt via the model in pi works without errors

## Notes

**2026-04-05T20:01:42Z**

Added glm-4.5-air entry to home/configs/pi-coding-agent/models.json under existing zai provider, before glm-5.1. Applied via home-manager. Verified: valid JSON, API call returns correct response with model glm-4.5-air. ACs 4-5 (pi model selector / sending prompt) require interactive verification.
