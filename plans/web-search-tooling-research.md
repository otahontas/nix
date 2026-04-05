# Web search tooling for AI agents

Research date: 2026-04-05

## Context

- Usage: ~500-800 searches/week (~2,000-3,200/month)
- Currently using a custom Firecrawl pi-coding-agent extension
- Already subscribed to Z.AI Max Coding Plan ($200/quarter)
- Goal: find cheaper or better alternatives to Firecrawl (€15/month)

---

## Options compared

### 1. Serper + Jina Reader

| Aspect                  | Details                                                                                                                                |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| **Search**              | Serper.dev (Google SERP API)                                                                                                           |
| **Scrape/read**         | Jina Reader (`r.jina.ai` for URLs, `s.jina.ai` for search)                                                                             |
| **Cost (our volume)**   | ~$2.50-5/month                                                                                                                         |
| **Serper pricing**      | $1.00/1k queries (starter), $0.75/1k at 500k tier. 2,500 free credits                                                                  |
| **Jina Reader pricing** | 10M free tokens, then token-based. Search mode (`s.jina.ai`) costs 10k tokens/request fixed. Free tier: 100 RPM                        |
| **Pros**                | Cheapest option; Serper is fast (1-2s latency); Jina Reader free tier generous                                                         |
| **Cons**                | Serper is a Google scraper (legal risk if Google cracks down); Jina Reader search limited to 100 RPM free; two separate APIs to manage |

### 2. Brave Search API

| Aspect                | Details                                                                                                                                                                              |
| --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **What it does**      | Search + LLM Context API (search + content extraction in one call)                                                                                                                   |
| **Cost (our volume)** | ~$5-11/month (after $5 free credits)                                                                                                                                                 |
| **Pricing**           | $5/1,000 requests, **$5 free credits every month** (covers first 1,000 searches)                                                                                                     |
| **Rate limit**        | 50 queries/second                                                                                                                                                                    |
| **Pros**              | Single API; independent index (not a scraper); SOC 2; Zero Data Retention; LLM Context API returns search + extracted content in one call; $5 free/month effectively halves the cost |
| **Cons**              | More expensive than Serper at volume; free credits only cover 1,000 searches                                                                                                         |

### 3. Z.AI MCP (Web Search + Web Reader)

| Aspect                | Details                                                                                                                                                                                             |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **What it does**      | Remote MCP server with `webSearchPrime` (search) + separate reader MCP (URL to markdown)                                                                                                            |
| **Setup**             | One-command MCP install in pi, Claude Code, Cursor, etc. HTTP-based, no local install                                                                                                               |
| **Cost (our volume)** | **$0** — included in Z.AI Max Coding Plan                                                                                                                                                           |
| **Pricing tiers**     | Lite ($20/qtr): 100 searches. Pro ($30/qtr): 1,000 searches. Max ($200/qtr): 4,000 searches                                                                                                         |
| **Pay-per-use API**   | $0.01/search if you have Z.AI API credits (but MCP requires Coding Plan)                                                                                                                            |
| **Quota**             | Max plan: 4,000 web searches + web readers combined/month                                                                                                                                           |
| **Pros**              | Already paid for (Max plan); native MCP integration; includes both search and reader; zero additional cost                                                                                          |
| **Cons**              | Quality of search results unknown relative to Google/Brave; 4,000 quota is tight for our volume (2,000-3,200/month); tied to Z.AI subscription; primarily Chinese-language model company (Zhipu AI) |

### 4. Firecrawl (current)

| Aspect           | Details                                                                             |
| ---------------- | ----------------------------------------------------------------------------------- |
| **Cost**         | €15/month subscription                                                              |
| **What it does** | Search + scrape + LLM-optimized extraction                                          |
| **Pros**         | All-in-one; good quality; custom pi extension already built                         |
| **Cons**         | Most expensive option; search quality may not justify 3-6× the cost of alternatives |

---

## Cost summary

| Option                   | Monthly cost (2,000-3,200 searches) | Notes                                      |
| ------------------------ | ----------------------------------- | ------------------------------------------ |
| **Z.AI MCP (Max plan)**  | **$0** (already subscribed)         | 4,000 searches included, covers our volume |
| **Serper + Jina Reader** | ~$2.50-5                            | Cheapest paid option                       |
| **Brave Search API**     | ~$5-11                              | Best single-API paid option                |
| **Firecrawl**            | ~€15                                | Current, most expensive                    |

---

## Recommendation

**Primary**: Use Z.AI MCP web search + web reader. Already included in Max plan, covers our volume. Replaces Firecrawl at zero additional cost.

**Fallback if quality is insufficient**: Brave Search API at ~$5-11/month (single API, independent index, $5 free/month).

**Cheapest paid option if leaving Z.AI**: Serper + Jina Reader at ~$2.50-5/month.

---

## Local alternatives

Running locally means zero per-unit cost and no rate limits from paid APIs. Search quality depends on upstream engines (Google, Bing, DuckDuckGo). Requires Docker on macOS.

### Recommended local stack: SearXNG (search) + Crawl4AI (scrape)

#### SearXNG

| Aspect              | Details                                                                                                                                                                                      |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **What**            | Self-hosted metasearch engine. Aggregates results from Google, Bing, Brave, DuckDuckGo, and 70+ other engines into a unified JSON API                                                        |
| **GitHub**          | [searxng/searxng](https://github.com/searxng/searxng) — 15k+ stars, actively maintained                                                                                                      |
| **Setup**           | `docker compose up -d` with one config change: enable `search.formats: [html, json]` in `settings.yml`. Runs at `http://localhost:8080`                                                      |
| **Resources**       | ~512MB–1GB RAM for the Docker container                                                                                                                                                      |
| **MCP integration** | [mcp-searxng](https://github.com/ihor-sokoliuk/mcp-searxng) (604 stars, MIT, actively maintained). Provides `searxng_web_search` and `web_url_read` tools. Connect via `SEARXNG_URL` env var |
| **Pros**            | No API keys needed; privacy-focused; aggregates multiple engines so no single point of failure; search quality comparable to Serper since it pulls from the same upstream engines            |
| **Cons**            | Returns snippets, not full page content (need Crawl4AI for that); depends on upstream engines' availability; Docker required                                                                 |

#### Crawl4AI

| Aspect              | Details                                                                                                               |
| ------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **What**            | Open-source LLM-friendly web crawler and scraper. Converts pages to clean markdown                                    |
| **GitHub**          | [unclecode/crawl4ai](https://github.com/unclecode/crawl4ai) — 63k+ stars, Apache 2.0, actively maintained             |
| **Setup**           | `pip install crawl4ai && crawl4ai-setup` or Docker: `docker run -d -p 11235:11235 unclecode/crawl4ai:latest`          |
| **Features**        | Async browser pool, headless Chromium, CSS/XPath/LLM extraction, stealth mode, session management, caching            |
| **MCP integration** | Built-in MCP server support in Docker deployment                                                                      |
| **Pros**            | Produces LLM-ready markdown; handles JS-rendered pages; fast parallel crawling; no API keys                           |
| **Cons**            | Heavier than a simple HTTP scraper (~1GB+ RAM for Docker + Chromium); browser overhead slower than API-based scraping |

#### How they work together

```
Agent query → SearXNG (search, returns snippets + URLs)
                → Crawl4AI (scrape top URLs → full markdown)
                    → Agent (processes content)
```

SearXNG handles search, Crawl4AI handles full-page scraping. Connect SearXNG to your agent via `mcp-searxng`, and Crawl4AI via its built-in MCP server or direct API.

### Other local options considered

#### duckduckgo-search (Python library)

| Aspect      | Details                                                                                                                                                         |
| ----------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **What**    | Python library for DuckDuckGo search. No API key needed                                                                                                         |
| **Setup**   | `pip install duckduckgo-search`                                                                                                                                 |
| **Pros**    | Simplest option; no Docker; fast; good for quick prototyping and scripts                                                                                        |
| **Cons**    | 100 req/min rate limit; DuckDuckGo sometimes changes HTML format, breaking the library; returns titles/snippets only, not full page content; no MCP integration |
| **Verdict** | Useful as a lightweight fallback for simple lookups, not a full search pipeline                                                                                 |

#### Whoogle

| Aspect      | Details                                                                 |
| ----------- | ----------------------------------------------------------------------- |
| **What**    | Self-hosted Google SERP scraper                                         |
| **GitHub**  | 11.4k stars, but unmaintained (last commit 2023)                        |
| **Verdict** | Skip — stale project, likely broken. SearXNG does the same thing better |

#### Khoj

| Aspect      | Details                                                                                                                                                    |
| ----------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **What**    | Self-hosted AI assistant with web search, document Q&A, and chat. 33.9k stars, AGPL-3.0                                                                    |
| **Cons**    | Uses Exa as web search provider (paid API with API keys), defeating the "local and free" goal. Full-stack AI assistant — overkill for just search + scrape |
| **Verdict** | Skip — adds cost and complexity we want to avoid                                                                                                           |

#### Playwright MCP / Stagehand

| Aspect      | Details                                                                                                      |
| ----------- | ------------------------------------------------------------------------------------------------------------ |
| **What**    | Browser automation tools with MCP support                                                                    |
| **Cons**    | Not search tools. Browser automation is 3–8x slower than Crawl4AI for scraping. Overkill for search + scrape |
| **Verdict** | Skip for search. Useful only if you need to interact with dynamic pages (click, fill forms)                  |

#### GPT Researcher

| Aspect      | Details                                                                                            |
| ----------- | -------------------------------------------------------------------------------------------------- |
| **What**    | Research agent that searches the web and generates reports                                         |
| **Verdict** | Skip — a research agent, not a search + scrape tool. Adds complexity without simplifying the stack |

### Local alternatives summary

| Option                 | Cost           | Setup complexity             | Best for                            |
| ---------------------- | -------------- | ---------------------------- | ----------------------------------- |
| **SearXNG + Crawl4AI** | $0             | Medium (2 Docker containers) | Full local search + scrape pipeline |
| **duckduckgo-search**  | $0             | Low (pip install)            | Quick lookups, scripts, prototyping |
| **Whoogle**            | $0             | Medium                       | Skip — unmaintained                 |
| **Khoj**               | Paid (Exa API) | High                         | Skip — overkill, adds cost          |

### Verdict on local options

Local tools are not a replacement for paid cloud APIs yet. They work best as a complement for cost savings. The SearXNG + Crawl4AI stack provides the closest Firecrawl-equivalent experience at zero cost, but requires Docker and more setup. For our use case, start with Z.AI MCP (already paid for) and fall back to SearXNG + Crawl4AI if search quality is good enough to drop cloud services entirely.
