/**
 * Firecrawl extension: web search and page scraping via Firecrawl REST API.
 * Requires FIRECRAWL_API_KEY environment variable.
 */

import { Type } from "@sinclair/typebox";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

async function firecrawlPost(
  path: string,
  body: unknown,
  signal?: AbortSignal,
): Promise<unknown> {
  if (!process.env.FIRECRAWL_API_KEY) {
    throw new Error("FIRECRAWL_API_KEY not set.");
  }
  const res = await fetch(`https://api.firecrawl.dev/v1/${path}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${process.env.FIRECRAWL_API_KEY}`,
    },
    body: JSON.stringify(body),
    signal,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Firecrawl ${path} failed (${res.status}): ${text}`);
  }
  return res.json();
}

export default function (pi: ExtensionAPI) {
  pi.registerTool({
    name: "firecrawl_search",
    label: "Firecrawl search",
    description:
      "Search the web using Firecrawl. Returns results with title, URL, and markdown content for each match.",
    promptSnippet:
      "firecrawl_search(query, limit?) — search the web and get results with content",
    promptGuidelines: [
      "Prefer firecrawl_search for web searches. It returns full page content, reducing the need for follow-up fetches.",
      "Use firecrawl_scrape when you need the content of a specific known URL.",
    ],
    parameters: Type.Object({
      query: Type.String({ description: "Search query" }),
      limit: Type.Optional(
        Type.Number({ description: "Max results (default 5)", default: 5 }),
      ),
    }),

    async execute(_id, params, signal) {
      const data = (await firecrawlPost(
        "search",
        {
          query: params.query,
          limit: params.limit ?? 5,
          scrapeOptions: { formats: ["markdown"] },
        },
        signal,
      )) as {
        data?: Array<{ title?: string; url?: string; markdown?: string }>;
      };

      const results = data.data ?? [];
      if (results.length === 0) {
        return { content: [{ type: "text", text: "No results found." }] };
      }

      const text = results
        .map((r, i) => {
          const parts: string[] = [];
          parts.push(`## ${i + 1}. ${r.title ?? "Untitled"}`);
          if (r.url) parts.push(`URL: ${r.url}`);
          if (r.markdown) parts.push(r.markdown);
          return parts.join("\n\n");
        })
        .join("\n\n---\n\n");

      return { content: [{ type: "text", text }] };
    },
  });

  pi.registerTool({
    name: "firecrawl_scrape",
    label: "Firecrawl scrape",
    description:
      "Scrape a single URL and return its content as markdown via Firecrawl.",
    promptSnippet: "firecrawl_scrape(url) — fetch a URL as markdown",
    parameters: Type.Object({
      url: Type.String({ description: "URL to scrape" }),
    }),

    async execute(_id, params, signal) {
      const data = (await firecrawlPost(
        "scrape",
        { url: params.url, formats: ["markdown"] },
        signal,
      )) as { data?: { markdown?: string } };

      const text = data.data?.markdown ?? "No content returned.";
      return { content: [{ type: "text", text }] };
    },
  });

  pi.on("session_start", (_event, ctx) => {
    if (!process.env.FIRECRAWL_API_KEY) {
      ctx.ui.notify(
        "FIRECRAWL_API_KEY not set. Run: pass insert api/firecrawl",
        "warning",
      );
    }
  });
}
