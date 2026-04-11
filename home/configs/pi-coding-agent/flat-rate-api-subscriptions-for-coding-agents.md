# Flat-rate API subscriptions for third-party coding agents

Research date: 2026-04-10 · Updated: 2026-04-10

## What we looked for

Flat-rate monthly subscription → API endpoint → usable in third-party coding tools (Claude Code, Cursor, Cline, pi, etc.). Excludes pay-per-token APIs and web-only chat subscriptions.

## Qualifying plans

### 1. OpenCode Go

**Status: $10/mo ($5 first month). Pay-as-you-go Zen balance available for overage. Cancel any time.**

|                  | Go                                                                                                             |
| ---------------- | -------------------------------------------------------------------------------------------------------------- |
| **Price**        | $10/month ($5 first month)                                                                                     |
| **Models**       | GLM-5.1, GLM-5, Kimi K2.5, MiMo-V2-Pro, MiMo-V2-Omni, MiniMax M2.7, MiniMax M2.5                               |
| **Quota**        | $12/5hr, $30/week, $60/month (usage-value based)                                                               |
| **API**          | OpenAI: `https://opencode.ai/zen/go/v1/chat/completions` · Anthropic: `https://opencode.ai/zen/go/v1/messages` |
| **API key**      | Via OpenCode console at opencode.ai/auth                                                                       |
| **Tools**        | Any agent with OpenAI or Anthropic compatible API (pi, Claude Code, Cursor, Cline, OpenCode, etc.)             |
| **Restrictions** | Usage limits defined in dollar value, not request count. Actual request count depends on model chosen.         |
| **Hosting**      | US, EU, Singapore. Zero-retention policy.                                                                      |

**Estimated requests per 5hr window** (varies by model):

| Model        | req/5hr | req/week | req/month |
| ------------ | ------- | -------- | --------- |
| GLM-5.1      | 880     | 2,150    | 4,300     |
| GLM-5        | 1,150   | 2,880    | 5,750     |
| Kimi K2.5    | 1,850   | 4,630    | 9,250     |
| MiMo-V2-Pro  | 1,290   | 3,225    | 6,450     |
| MiMo-V2-Omni | 2,150   | 5,450    | 10,900    |
| MiniMax M2.7 | 14,000  | 35,000   | 70,000    |
| MiniMax M2.5 | 20,000  | 50,000   | 100,000   |

**Overage**: If you also have Zen (pay-as-you-go) credits, enable "Use balance" in the console and Go falls back to your Zen balance after limits are reached.

**API compatibility**: MiniMax M2.5/M2.7 use Anthropic messages format. All others use OpenAI chat completions format.

### 2. MiniMax Token Plan

**Status: All tiers available. Renamed from "Coding Plan" to "Token Plan" in April 2026. Now uses M2.7 (upgraded from M2.5). Both standard and high-speed tiers available.**

**Standard tiers** (M2.7 ~50 tok/s, 100 off-peak):

|                     | Starter          | Standard          | Pro               | Max               |
| ------------------- | ---------------- | ----------------- | ----------------- | ----------------- |
| **Price**           | ~$8/mo ($100/yr) | ~$17/mo ($200/yr) | ~$42/mo ($500/yr) | ~$67/mo ($800/yr) |
| **Req / 5hr**       | 1,500            | 4,500             | 15,000            | 30,000            |
| **OpenClaw agents** | ~1               | 1-2               | 2-3               | 4-5               |

**High-speed tiers** (M2.7-highspeed ~100 tok/s sustained):

|                     | Standard HS       | Pro HS            | Max HS               |
| ------------------- | ----------------- | ----------------- | -------------------- |
| **Price**           | ~$33/mo ($400/yr) | ~$67/mo ($800/yr) | ~$125/mo ($1,500/yr) |
| **Req / 5hr**       | 4,500             | 15,000            | 30,000               |
| **OpenClaw agents** | 1-2               | 2-3               | 4-5                  |

**All tiers include**:

- **Model**: MiniMax M2.7 (or M2.7-highspeed on HS tiers)
- **API**: OpenAI-compatible at MiniMax platform
- **API key**: Via platform.minimax.io
- **Tools**: Claude Code, Cursor, Cline, OpenCode, Codex CLI, Roo Code, Kilo Code, TRAE, Droid, Grok CLI
- **MCP tools**: Web Search, Image Understanding
- **Multimodal**: image generation, speech, music, video generation included
- **Hosting**: MiniMax infrastructure (China-based)
- **Annual discount**: 2 months free on yearly billing

**Key features**:

- **Single model focus**: MiniMax M2.7 is the successor to M2.5 (80.2% SWE-bench). M2.7 adds stronger agentic capabilities, multi-agent collaboration, and improved document generation.
- **High-speed option**: M2.7-highspeed delivers ~100 tok/s sustained, ~3× faster than competing models. Costs 2× the standard tier.
- **Multimodal included**: image generation, speech synthesis, music, and video generation all included in the subscription — not just text.
- **OpenClaw support**: explicitly supports 1-5 parallel OpenClaw agents depending on tier.
- **Annual discount**: 2 months free on yearly billing.
- **Invite program**: 10% voucher for inviter, 10% off for invitee.

**Caveats**:

- Only MiniMax models — no GLM, Kimi, or Qwen. If you want model diversity, pair with another plan.
- China-hosted infrastructure. Variable global latency.
- No zero-retention data policy stated.

### 3. Alibaba Cloud AI Coding Plan

**Status: Pro ($50/mo) is the only tier available for new signups. Lite ($10/mo) discontinued March 20, 2026. Pro is frequently sold out — restocks daily at 00:00 UTC+8.**

|                  | Pro                                                                                                                                                      |
| ---------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Price**        | $50/month                                                                                                                                                |
| **Models**       | qwen3.6-plus (vision), kimi-k2.5 (vision), glm-5, MiniMax-M2.5, qwen3.5-plus (vision), qwen3-max-2026-01-23, qwen3-coder-next, qwen3-coder-plus, glm-4.7 |
| **Quota**        | 6,000 req/5hr, 45,000 req/week, 90,000 req/month                                                                                                         |
| **API**          | Anthropic: `https://coding-intl.dashscope.aliyuncs.com/apps/anthropic` · OpenAI: `https://coding-intl.dashscope.aliyuncs.com/v1`                         |
| **API key**      | `sk-sp-xxxxx` (plan-specific, different from standard Model Studio key)                                                                                  |
| **Tools**        | Claude Code, Cursor, Cline, OpenCode, Codex, JetBrains, Qwen Code, Kilo Code/CLI, pi                                                                     |
| **Restrictions** | Interactive coding tools only — no scripts, backends, or batch API calls. Non-refundable. Personal use only (no sharing).                                |

### 4. Z.ai GLM Coding Plan

**Status: All tiers available but limited daily restock at 10:00 UTC+8. Prices raised 30%+ on Feb 12, 2026.**

|                        | Lite                                                                                                  | Pro                                                                                                       | Max                     |
| ---------------------- | ----------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------- | ----------------------- |
| **Price**              | ~$10/mo ($30/qtr)                                                                                     | ~$30/mo ($90/qtr)                                                                                         | ~$80/mo ($240/qtr)      |
| **Models (all)**       | GLM-5.1, GLM-5-Turbo, GLM-4.7, GLM-4.6, GLM-4.5-Air                                                   | same + GLM-5                                                                                              | same + GLM-5            |
| **Quota**              | 3× Claude Pro                                                                                         | 5× Lite (15× Claude Pro)                                                                                  | 4× Pro (60× Claude Pro) |
| **API**                | Anthropic: `https://api.z.ai/api/anthropic/v1` (intl) · `https://open.bigmodel.cn/api/anthropic` (CN) |                                                                                                           |                         |
| **Speed**              | Baseline                                                                                              | 40–60% faster than Lite                                                                                   | Peak-hour guaranteed    |
| **MCP tools**          | Limited                                                                                               | Vision, Web Search, Web Reader, Zread                                                                     | Full                    |
| **GLM-5.x multiplier** | —                                                                                                     | Peak (14:00–18:00 UTC+8): 3×, off-peak: 2×. Promo: GLM-5.1/5-Turbo at 1× off-peak until end of April 2026 | same                    |

## Model benchmarks (April 2026)

Data from SWE-bench Verified (BenchLM.ai, swebench.com), LLM-Stats, Artificial Analysis.

### SWE-bench Verified

| Model        | Plan    | Score                | Context |
| ------------ | ------- | -------------------- | ------- |
| MiniMax M2.5 | Alibaba | 80.2%                | 256K    |
| Qwen3.6 Plus | Alibaba | 78.8%                | 1M      |
| GLM-5.1      | Z.ai    | ~78% (self-reported) | 200K    |
| GLM-5        | Both    | 77.8%                | 200K    |
| Kimi K2.5    | Alibaba | 76.8%                | 262K    |
| Qwen3.5 397B | Alibaba | 76.2%                | 262K    |
| GLM-4.7      | Both    | 73.8%                | 200K    |

For reference — top proprietary models: Claude Opus 4.6 (80.8%), Gemini 3.1 Pro (80.6%), GPT-5.2 (80.0%).

### Other benchmarks

| Model        | GPQA Diamond | AIME 2025 | HLE   | Arena Elo (Chat) |
| ------------ | ------------ | --------- | ----- | ---------------- |
| Qwen3.6 Plus | 90%          | —         | —     | —                |
| Qwen3.5 397B | 88.4%        | 91.3%     | 28.7% | 1067             |
| Kimi K2.5    | 87.6%        | 96.1%     | 50.2% | 988              |
| GLM-5        | 86.0%        | 92.7%     | —     | 1451             |
| GLM-4.7      | 85.7%        | 95.7%     | 42.8% | —                |

### Speed (approximate)

| Model        | Output tok/s | Notes                  |
| ------------ | ------------ | ---------------------- |
| GLM-5.1      | ~44          | Slowest frontier model |
| GLM-5        | ~47          |                        |
| Kimi K2.5    | ~47          | Measured on Fireworks  |
| Qwen3.5-Plus | ~80-100      | Via Alibaba API        |
| MiniMax M2.5 | ~60-80       |                        |

### Per-token pricing (for reference, not subscription)

| Model        | Input $/M | Output $/M |
| ------------ | --------- | ---------- |
| GLM-5        | $1.00     | $3.20      |
| GLM-4.7      | $0.39     | $1.70      |
| Kimi K2.5    | $0.60     | $2.50      |
| MiniMax M2   | $0.30     | $1.00      |
| Qwen3.5-Plus | $0.26     | $1.56      |

## Side-by-side: all qualifying plans (budget tiers)

Comparing the entry-level tiers of each provider:

|                    | **OpenCode Go**              | **MiniMax Starter**             | **Z.ai GLM Lite**           | **Alibaba Cloud Pro**        |
| ------------------ | ---------------------------- | ------------------------------- | --------------------------- | ---------------------------- |
| **Price**          | $10/mo                       | ~$8/mo ($100/yr)                | ~$10/mo ($30/qtr)           | $50/mo                       |
| **Models**         | 7 (GLM, Kimi, MiMo, MiniMax) | 1 (MiniMax M2.7)                | 5 (GLM family only)         | 9 (Qwen, Kimi, GLM, MiniMax) |
| **Best SWE-bench** | MiniMax M2.5: 80.2%          | M2.7: ~80%+                     | GLM-5.1: ~78%               | MiniMax M2.5: 80.2%          |
| **Max context**    | 262K (Kimi K2.5)             | 196K (M2.7)                     | 203K (GLM-5.x)              | 1M (Qwen3.5/3.6 Plus)        |
| **Quota / 5hr**    | $12 value (~880–20K req)     | 1,500 req                       | ~80 prompts                 | 6,000 req                    |
| **Quota / month**  | $60 value (~4.3K–100K req)   | ~900K req (est.)                | ~3× Claude Pro              | 90,000 req                   |
| **Speed**          | 47–80 tok/s                  | ~50 tok/s (100 off-peak)        | ~44 tok/s                   | 80–100 tok/s                 |
| **Vision**         | Yes (MiMo-V2-Omni)           | Yes (image understanding MCP)   | Limited                     | Yes (Qwen3.5/3.6, Kimi K2.5) |
| **MCP tools**      | None                         | Web Search, Image Understanding | Limited (Pro+ only)         | None                         |
| **Availability**   | Open signup                  | Open signup                     | Limited restock 10:00 UTC+8 | Limited restock 00:00 UTC+8  |
| **Hosting**        | US, EU, Singapore            | China                           | China                       | China                        |
| **Data privacy**   | Zero retention               | Standard                        | Standard                    | Standard                     |
| **Commitment**     | Monthly                      | Annual                          | Quarterly                   | Monthly                      |

## Side-by-side: OpenCode Go vs Z.ai GLM Max (budget vs high-end)

The cheapest plan vs the most expensive — is $80/mo worth it?

|                        | **OpenCode Go ($10/mo)**                    | **Z.ai GLM Max (~$80/mo)**                      |
| ---------------------- | ------------------------------------------- | ----------------------------------------------- |
| **Price**              | $10/mo, monthly cancel                      | ~$80/mo ($240/qtr upfront)                      |
| **Models**             | 7 models from 4 providers                   | 6 GLM variants                                  |
| **Best SWE-bench**     | MiniMax M2.5: **80.2%**                     | GLM-5.1: **~78%**                               |
| **Max context**        | 262K (Kimi K2.5)                            | 203K (GLM family)                               |
| **Quota / 5hr**        | $12 value: 880–20K req depending on model   | ~1,600 prompts (before GLM-5.x multiplier)      |
| **Quota / month**      | $60 value: 4.3K–100K req depending on model | ~60× Claude Pro (~230K req before multiplier)   |
| **GLM-5.x multiplier** | None (flat dollar value)                    | Peak: **3×**, off-peak: **2×**                  |
| **Speed**              | MiniMax M2.5: ~60-80 tok/s                  | ~44 tok/s, guaranteed at peak                   |
| **MCP tools**          | **None**                                    | **Full**: Vision, Web Search, Web Reader, Zread |
| **API format**         | OpenAI + Anthropic                          | OpenAI + Anthropic                              |
| **Hosting**            | US, EU, Singapore                           | China                                           |
| **Data privacy**       | Zero-retention policy                       | Standard                                        |
| **Availability**       | Open signup                                 | Limited daily restock 10:00 UTC+8               |
| **Commitment**         | Monthly, cancel anytime                     | Quarterly ($240 upfront)                        |

**Where OpenCode Go wins**: 8× cheaper, better best model (MiniMax M2.5 at 80.2%), model diversity from 4 providers, faster speed with MiniMax, larger context (262K), better hosting (US/EU/SG), zero retention, open signup, monthly cancel.

**Where Z.ai GLM Max wins**: 50× more GLM-5.1 quota (4,300 vs ~230K req/month), built-in MCP tools (vision, web search, web reader, Zread), GLM-5 exclusive access (strongest agentic reasoning — #1 open-source on Vending Bench 2), peak-hour speed guarantee, no overage concerns ever.

**Bottom line**: If you use MiniMax M2.5 as your daily model, OpenCode Go gives comparable quota and better quality at 1/8 the price. If you need GLM-5 specifically (agentic reasoning, MCP tools) or burn through thousands of requests daily on GLM-4.7 (no multiplier), Z.ai Max justifies the price. For most individual developers, OpenCode Go + MiniMax M2.5 is the better value.

## Current setup analysis

### What's configured

**pi-coding-agent** (primary daily driver):

- Default: `zai/glm-5.1` with `high` thinking
- Provider: Z.ai GLM Coding Plan **Max tier** (~$80/mo) via OpenAI-compatible API
- API key: `ZAI_API_KEY` env var
- Endpoint: `https://api.z.ai/api/coding/paas/v4`
- Also available: `zai/glm-5`, `zai/glm-4.7`, `zai/glm-4.5-air`

**GitHub Copilot** (secondary):

- OAuth-based, free educational quota
- Models: `github-copilot/claude-opus-4.5`, `github-copilot/gpt-5.3-codex`
- Proxy endpoint: `proxy.individual.githubcopilot.com`

**Ollama** (local):

- `gemma4:e2b` — 128K context, non-reasoning, for offline/lightweight use

### Requirements

1. **Flat-rate cost** — predictable monthly spend, no surprise bills from agent loops
2. **API access for third-party tools** — pi, Claude Code, Cursor, Cline
3. **Strong coding performance** — SWE-bench 75%+ for real bug-fixing and refactoring
4. **200K+ context window** — enough for typical repos and multi-file work
5. **Anthropic or OpenAI API compat** — pi needs one of these
6. **MCP tools** — web search, vision, file reading enhance agentic workflows
7. **Enough quota for daily heavy use** — agentic coding burns through prompts fast

### Pros of current setup

- **Predictable cost** — Z.ai GLM Max at ~$80/mo gives 60× Claude Pro quota, enough for heavy daily use
- **GLM-5.1 is strong** — 94.6% of Claude Opus 4.6 on Z.ai's own coding benchmark, SWE-bench ~78%
- **200K context** — sufficient for most tasks
- **MCP tools included** — vision, web search, web reader, Zread at no extra cost
- **GitHub Copilot as fallback** — free access to Claude Opus 4.5 and GPT-5.3 Codex for critical tasks
- **Ollama for offline** — local model available when no internet
- **pi integration works** — OpenAI-compatible API, already configured

### Cons of current setup

- **Single provider risk** — if Z.ai has outages or rate limits, only fallback is Copilot (which requires manual switching)
- **GLM-5.x multiplier** — peak hours (14:00–18:00 UTC+8) cost 3× quota. Promo 1× ends April 30, then 2× off-peak / 3× peak. Even with multiplier, Max tier has enough headroom.
- **Speed** — GLM-5.1 at ~44 tok/s is the slowest frontier coding model. Max tier guarantees peak-hour speed but the ceiling is still low.
- **Price** — $80/mo is 8× OpenCode Go ($10) and 1.6× Alibaba Cloud Pro ($50). Investigating whether cheaper alternatives provide comparable value.
- **No model diversity** — only GLM family. Can't try Qwen, Kimi, or MiniMax models without a separate subscription
- **Limited context** — 200K vs 1M on Alibaba (Qwen3.5/3.6 Plus). Large repos hit the ceiling
- **Quota opacity** — no published monthly prompt count, just "15× Claude Pro". Hard to budget
- **Daily restock lottery** — can't always get or renew the plan exactly when needed
- **GitHub Copilot limitations** — educational/free tier may have rate limits, proxy endpoint can be flaky
- **No Anthropic-native endpoint** — pi uses OpenAI-compatible API for Z.ai. Anthropic-native might have better tool-calling support for some workflows

## No new flat-rate API subscriptions found (April 2026 sweep)

Searched specifically for:

- New providers launching flat-rate API plans post-April 2026
- Regional providers (Korean, Japanese, European, Middle Eastern cloud AI)
- Proxy/aggregator services bundling multiple models under a subscription
- Updates to existing providers (Z.ai, Alibaba)

**Result: the market now has 4 qualifying providers with 5+ plan tiers** — OpenCode Go ($10/mo), MiniMax Token Plan ($8-125/mo), Alibaba Cloud ($50/mo), and Z.ai GLM ($10-80/mo). No Korean (Naver, Kakao), Japanese (Sakura, LINE/Yahoo), European (Mistral, Aleph Alpha), or Middle Eastern providers offer flat-rate API access usable in third-party coding tools.

The market is moving in the opposite direction for IDE tools (Kiro, Augment Code, Windsurf are own-tool-only), but several notable flat-rate API entrants have appeared: OpenCode Go ($10/mo, 7 models, US/EU/SG hosting), and MiniMax Token Plan ($8/mo+, single-model focus with high-speed option at ~100 tok/s).

## Pay-per-token alternatives under $30-50/mo

Since flat-rate API options are limited to 4 providers, pay-per-token APIs are the practical fallback. Several are cheap enough that monthly spend stays well under $50 for heavy coding agent use.

### OpenCode Zen (curated pay-per-token gateway)

Not a flat-rate plan, but worth highlighting: OpenCode Zen is a curated AI gateway by the OpenCode team that offers tested, benchmarked models for coding agents. **Zero markup on provider pricing** — sold at cost with only processing fees.

**Key features**:

- 30+ models: GPT-5.x series, Claude 4.x series, Gemini 3.x, plus open models (GLM-5/5.1, Kimi K2.5, MiniMax M2.5)
- OpenAI, Anthropic, and Google-compatible API endpoints at `opencode.ai/zen/v1/...`
- Usable with any agent, not just OpenCode
- Free models: MiniMax M2.5 Free, Qwen3.6 Plus Free, Nemotron 3 Super Free, Big Pickle (limited time)
- All models hosted in US, zero data retention
- BYOK: bring your own OpenAI/Anthropic keys for those models
- Team features: workspace billing, monthly spend limits per member, model access controls
- Auto-reload when balance drops below $5

**Notable pricing** (per 1M tokens):
| Model | Input | Output | Cached Read |
|---|---|---|---|
| GPT 5.4 Nano | $0.20 | $1.25 | $0.02 |
| Gemini 3 Flash | $0.50 | $3.00 | $0.05 |
| GPT 5.4 Mini | $0.75 | $4.50 | $0.075 |
| Kimi K2.5 | $0.60 | $3.00 | $0.10 |
| GLM 5.1 | $1.40 | $4.40 | $0.26 |
| GPT 5.3 Codex | $1.75 | $14.00 | $0.175 |
| Claude Sonnet 4.6 | $3.00 | $15.00 | $0.30 |
| GPT 5.4 | $2.50 | $15.00 | $0.25 |
| Claude Opus 4.6 | $5.00 | $25.00 | $0.50 |

**Zen vs direct API pricing**: Identical or very close to direct provider pricing. The value is curation (tested model/provider combos) and convenience (single API key for all providers).

### Other pay-per-token alternatives

### Estimated monthly costs for coding agent use

Assuming ~200 agent requests/day × 30 days, average 2K input + 1K output tokens per request (conservative for agentic coding — actual agent sessions are often larger due to context re-sending):

| Model                 | Input $/M | Output $/M | Est. monthly cost | Context | SWE-bench |
| --------------------- | --------- | ---------- | ----------------- | ------- | --------- |
| DeepSeek V3.2 (chat)  | $0.14     | $0.28      | ~$3-8             | 128K    | ~69%      |
| DeepSeek V4           | $0.30     | $0.50      | ~$7-17            | 1M      | 81%       |
| Kimi K2 (0905)        | $0.60     | $2.50      | ~$22-55           | 262K    | —         |
| Kimi K2.5             | $0.60     | $3.00      | ~$25-65           | 262K    | 76.8%     |
| Qwen3.5-Plus (direct) | $0.26     | $1.56      | ~$12-30           | 262K    | 76.2%     |
| GLM-4.7 (direct)      | $0.39     | $1.70      | ~$13-33           | 200K    | 73.8%     |
| Gemini 2.5 Flash      | $0.30     | $2.50      | ~$15-37           | 1M      | —         |
| GPT-4o-mini           | $0.15     | $0.60      | ~$5-12            | 128K    | —         |

**DeepSeek V4 is the standout** — 81% SWE-bench (matching Claude Opus 4.6 at 80.8%), 1M context, and estimated $7-17/mo for heavy use. At cache hit pricing ($0.03/M input), costs drop even further. The main trade-off is reliability (China-hosted infrastructure, variable latency).

### DeepSeek V4 details

- **Pricing**: $0.30/M input, $0.50/M output, $0.03/M cache hit
- **Context**: 1M tokens
- **SWE-bench Verified**: 81%
- **OpenAI-compatible API** at `api.deepseek.com`
- **671B total params, 37B active (MoE)**
- **Automatic context caching** with 90% discount on cache hits
- **Off-peak discounts**: 50% off V4 during 16:30-00:30 GMT
- **Free tier**: 5M tokens on signup, no credit card required
- **Caveats**: No hard rate limits but capacity constraints during peak; hosted in China; variable global latency

### When pay-per-token beats flat-rate

| Usage pattern             | Best option                                                       | Monthly cost |
| ------------------------- | ----------------------------------------------------------------- | ------------ |
| Light (<50 req/day)       | DeepSeek V3.2 pay-per-token                                       | $1-5         |
| Moderate (50-200 req/day) | DeepSeek V4 pay-per-token                                         | $5-20        |
| Heavy (200-500 req/day)   | Z.ai GLM Pro (flat-rate ~$30) or OpenCode Go ($10) or DeepSeek V4 | $10-30       |
| Very heavy (500+ req/day) | Alibaba Cloud Pro ($50) or OpenCode Go + Zen overage              | $10-50       |
| Need model diversity      | Alibaba Cloud Pro ($50)                                           | $50          |
| Need 1M context + speed   | Alibaba Cloud Pro (Qwen3.5/3.6 Plus)                              | $50          |

## Proxy and aggregator tools

These don't provide new subscriptions but help unify existing ones:

### VibeProxy

- macOS menu bar app that proxies existing subscriptions (Claude Code, ChatGPT, Gemini, Qwen) to any OpenAI-compatible tool
- Handles OAuth auth, token rotation, multi-account round-robin
- Runs on `localhost:8317`, exposes Anthropic + OpenAI endpoints
- No additional cost — uses subscriptions you already have
- Apple Silicon only (M1+)

### AI Worker Proxy

- Open-source Cloudflare Workers proxy for multi-provider routing
- Supports Anthropic, Google Gemini, OpenAI, OpenAI-compatible, Cloudflare AI
- Token rotation, failover, streaming, tool calling pass-through
- Free hosting on Cloudflare Workers (100K requests/day on free tier)
- BYOK — you provide all API keys

### OpenRouter

- Largest model aggregator with 500+ models
- Per-token pricing, no subscription
- Useful for trying many models without managing separate accounts
- Supports Kimi K2.5, DeepSeek V4, Qwen, GLM, etc.

## GitHub Copilot BYOK

GitHub Copilot now supports **Bring Your Own Key** (public preview as of Jan 2026):

**Supported providers**: Anthropic, OpenAI, Azure OpenAI, AWS Bedrock, Google AI Studio, xAI, Ollama, any OpenAI-compatible endpoint

**How it works**:

- Enterprise/Business admins add API keys at org or enterprise level
- BYOK usage is billed by your provider, not GitHub — doesn't count against Copilot premium request quotas
- Available in Agent, Plan, Ask, and Edit modes in VS Code, JetBrains, Eclipse, Xcode

**Copilot SDK BYOK** (for developers building with the SDK):

- Available on all Copilot plans (including individual)
- Supports OpenAI, Anthropic, Azure, Ollama, any OpenAI-compatible
- Configure `provider` with `type`, `baseUrl`, `apiKey`
- BYOK requests don't count against premium request quotas

**Limitations**:

- Enterprise/Business only for the admin-configured BYOK (not available for individual Copilot users in the IDE)
- SDK BYOK available to all but requires code changes
- No Entra ID / managed identity support — static API keys only
- Only models your provider supports are available

**Relevance**: BYOK doesn't create new flat-rate options, but it lets you use pay-per-token keys (like DeepSeek) through Copilot's interface without burning Copilot quotas.

## OpenAI subscription vs API comparison

OpenAI has both subscription plans (ChatGPT) and pay-per-token API access. These are **billed separately** — ChatGPT subscriptions don't include API access, and API keys don't work with ChatGPT. Here's how they compare for coding agent use:

### ChatGPT subscription plans

| Plan       | Price                | Models                                     | Context (instant) | Context (reasoning) | Codex CLI | Third-party API |
| ---------- | -------------------- | ------------------------------------------ | ----------------- | ------------------- | --------- | --------------- |
| Free       | $0                   | GPT-5.3 (limited)                          | 27K               | Varies              | Limited   | ✗               |
| Go         | $8/mo                | GPT-5.3 (more)                             | 54K               | 256K                | Yes       | ✗               |
| Plus       | $20/mo               | GPT-5.4 Thinking, GPT-5.3                  | 54K               | 256K                | Expanded  | ✗               |
| Pro        | $100/mo              | GPT-5.4 Pro, 5.4 Thinking, 5.3 (unlimited) | 128K              | 400K                | Maximum   | ✗               |
| Business   | $20/user/mo (annual) | GPT-5.4 (unlimited), 5.4 Thinking, 5.4 Pro | 54K               | 256K                | Yes       | ✗               |
| Enterprise | Custom               | All models, expanded context               | 128K              | 256K                | Yes       | ✗               |

**Key points**:

- None of the ChatGPT subscription plans provide third-party API access
- **Codex CLI** (OpenAI's own coding agent) works with ChatGPT Plus/Pro subscriptions — it uses your subscription credits, not API billing
- Codex CLI is the only way to use a ChatGPT subscription for agentic coding, but it's OpenAI's own tool, not a general API
- ChatGPT subscriptions are web/app/IDE-only — no `base_url` you can point pi, Claude Code, or Cursor at
- The new **Go** plan at $8/mo is interesting for budget Codex CLI use

### OpenAI API pricing (per 1M tokens)

For third-party coding agents, you need the API (separate billing):

| Model         | Input  | Cached input | Output  | Context |
| ------------- | ------ | ------------ | ------- | ------- |
| GPT-5.4 Nano  | $0.20  | $0.02        | $1.25   | 128K    |
| GPT-5.4 Mini  | $0.75  | $0.075       | $4.50   | 128K    |
| GPT-5.4       | $2.50  | $0.25        | $15.00  | 128K    |
| GPT-5.4 Pro   | $30.00 | —            | $180.00 | 128K    |
| GPT-5.3 Codex | $1.75  | $0.175       | $14.00  | 128K    |

Additional options:

- **Batch API**: 50% off all prices (24hr turnaround)
- **Flex processing**: 50% off (slower, occasional unavailability)
- **Priority processing**: 2× standard (guaranteed speed)
- **Long context (>270K)**: 2× input and 1.5× output on GPT-5.4
- **Web search**: $10/1k calls

### Estimated monthly API cost for coding agent use

Same assumption as earlier (~200 req/day, 2K input + 1K output per request):

| Model         | Est. monthly cost |
| ------------- | ----------------- |
| GPT-5.4 Nano  | ~$6-15            |
| GPT-5.4 Mini  | ~$20-50           |
| GPT-5.3 Codex | ~$30-75           |
| GPT-5.4       | ~$55-140          |

GPT-5.4 Nano at $0.20/$1.25 is surprisingly competitive with DeepSeek V4 ($0.30/$0.50) on input pricing, though output is 2.5× more expensive. With the 90% cache discount ($0.02/M cached input), heavy context-reuse patterns could be very affordable.

### When OpenAI makes sense for third-party agents

| Scenario                                    | Best choice                         |
| ------------------------------------------- | ----------------------------------- |
| Want OpenAI models in pi/Claude Code/Cursor | API key with GPT-5.4 Nano/Mini      |
| Budget OpenAI agent use                     | GPT-5.4 Nano via API ($6-15/mo)     |
| Need GPT-5.4 quality                        | GPT-5.4 via API ($55-140/mo)        |
| Only use OpenAI's own Codex CLI             | ChatGPT Plus ($20/mo) or Go ($8/mo) |
| Need GPT-5.4 Pro reasoning                  | ChatGPT Pro ($100/mo) or API ($$$)  |

## Subscription restriction landscape (April 2026)

Both major subscription providers have now explicitly restricted or excluded third-party tool usage from their subscriptions:

### Anthropic — Claude Pro/Max third-party tool ban

Effective **April 4, 2026**, Anthropic enforced a policy that **Claude Pro ($20/mo) and Claude Max ($100/mo) subscriptions no longer cover third-party tool usage**. Previously, subscribers could use OAuth tokens to access Claude through tools like OpenClaw, NanoClaw, and other agents.

**What happened**:

- Announced by Boris Cherny (Head of Claude Code) on April 4, 2026
- Claude subscription OAuth tokens are now restricted to official products only: Claude.ai, Claude Code, Claude Desktop, Claude Cowork
- All third-party tools (OpenClaw, NanoClaw, OpenCode, pi, etc.) must use independent API keys with pay-per-token billing
- **Compensation**: One-time credit equal to monthly fee ($20 Pro, $100 Max), must be used by April 17, 2026
- Pre-purchase discount packs up to 30% off for high-volume users

**Why**: Third-party tools bypass Anthropic's Prompt Cache optimizations, causing disproportionate compute costs. A $200/mo Max subscription was being used to run $1,000-5,000 worth of workloads through third-party agents. This "token arbitrage" model is now shut down.

**Timeline**:

- Nov 2025: OpenClaw released, supports Claude OAuth tokens
- Feb 14, 2026: OpenClaw creator Peter Steinberger joins OpenAI
- Feb 20, 2026: Anthropic updates terms to explicitly prohibit OAuth token use in third-party tools
- Mar 2026: Server-side blocking deployed without announcement
- Apr 4, 2026: Full enforcement

**Impact on this research**: Anthropic was never a qualifying flat-rate provider (Claude subscriptions never offered a third-party API endpoint), but this confirms it explicitly. Claude Code remains covered by subscriptions, but only as Anthropic's own tool.

**VibeProxy impact**: VibeProxy previously could proxy Claude subscriptions to other tools via OAuth. This restriction likely breaks or limits that functionality for Claude.

### OpenAI — ChatGPT subscriptions remain own-tool-only

OpenAI has **not** followed Anthropic's lead in restricting anything — they never allowed third-party API access from subscriptions to begin with. Notably, OpenAI has publicly positioned itself as more welcoming to third-party integration, in contrast to Anthropic's restriction.

ChatGPT subscriptions ($0-200/mo) are web/app/Codex CLI only. For third-party agents, you need a separate API key with pay-per-token billing. The one exception is **Codex CLI** (OpenAI's own coding agent), which uses subscription credits — but that's not a general API.

### Implications

The subscription restriction trend means the 3 qualifying flat-rate API plans (OpenCode Go, Alibaba Cloud, Z.ai) are increasingly valuable — they're the only way to get predictable monthly costs with third-party agent tools. Pay-per-token with caching (DeepSeek V4, GPT-5.4 Nano) is the alternative for cost-conscious users.

## Excluded providers (updated)

| Provider                | Reason                                                                                                                                                                                                                                                                                                                       |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| DeepSeek                | Pay-per-token only ($0.14/$0.28 V3.2, $0.30/$0.50 V4). No subscription plan. Very cheap — $3-20/mo typical spend. Practical alternative to flat-rate.                                                                                                                                                                        |
| Mistral                 | Pay-per-token only. No subscription coding plan.                                                                                                                                                                                                                                                                             |
| OpenRouter              | Aggregator, per-token billing. No subscription model.                                                                                                                                                                                                                                                                        |
| Together AI             | Per-token only. No subscription tier.                                                                                                                                                                                                                                                                                        |
| Fireworks AI            | Per-token only. No subscription tier.                                                                                                                                                                                                                                                                                        |
| Google Gemini           | API is per-token. Gemini Code Assist subscription is own-tool only, not API.                                                                                                                                                                                                                                                 |
| OpenAI                  | API is pay-per-token (GPT-5.4 Nano $0.20/$1.25, GPT-5.4 $2.50/$15.00). ChatGPT subscriptions ($0-100/mo) are own-tool-only (web/app/Codex CLI). No third-party API access from subscriptions. API billing is separate.                                                                                                       |
| Anthropic               | API is per-token. Claude Pro/Max are web-only, not third-party API. **April 4, 2026**: Explicitly banned OAuth tokens from third-party tools (OpenClaw, etc.). Claude subscriptions now only work with Claude.ai, Claude Code, Claude Desktop, Claude Cowork. Third-party usage requires API key with pay-per-token billing. |
| Kiro (AWS)              | IDE tool only ($0-200/mo). Uses Claude models internally. No API access.                                                                                                                                                                                                                                                     |
| Augment Code            | IDE/CLI tool ($20-200/mo). Credit-based. No third-party API access.                                                                                                                                                                                                                                                          |
| Windsurf                | IDE tool ($15-200/mo). Credit-based. No third-party API access.                                                                                                                                                                                                                                                              |
| Cursor                  | IDE tool ($20-200/mo). Credit-based. No third-party API access.                                                                                                                                                                                                                                                              |
| Kimi Code (Moonshot AI) | Moderato subscription (~$7/wk) includes API access for Claude Code, Roo Code, Kimi CLI (300-1,200 calls/5hr, 100 tok/s). **Qualifies as a flat-rate plan** but weekly billing and single-model (Kimi K2.5 only). Kimi K2.5 also available via Alibaba Cloud and OpenCode Go plans.                                           |
| MiniMax Token Plan      | Listed above as qualifying plan #2. Included here for cross-reference.                                                                                                                                                                                                                                                       |
