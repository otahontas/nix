/**
 * Firecrawl extension for pi coding agent.
 *
 * Provides web search and page scraping via the Firecrawl REST API.
 * Requires FIRECRAWL_API_KEY environment variable.
 */

import { Type } from "@sinclair/typebox";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const SearchParams = Type.Object({
  query: Type.String({ description: "Search query" }),
  limit: Type.Optional(
    Type.Number({ description: "Max results (default 5)", default: 5 }),
  ),
});

const ScrapeParams = Type.Object({
  url: Type.String({ description: "URL to scrape" }),
});

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
    parameters: SearchParams,

    async execute(_id, params, signal, onUpdate) {
      if (!process.env.FIRECRAWL_API_KEY) {
        return {
          content: [
            { type: "text", text: "Error: FIRECRAWL_API_KEY not set." },
          ],
          isError: true,
        };
      }

      const res = await fetch("https://api.firecrawl.dev/v1/search", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${process.env.FIRECRAWL_API_KEY}`,
        },
        body: JSON.stringify({
          query: params.query,
          limit: params.limit ?? 5,
          scrapeOptions: { formats: ["markdown"] },
        }),
        signal,
      });

      if (!res.ok) {
        const body = await res.text();
        return {
          content: [
            {
              type: "text",
              text: `Firecrawl search failed (${res.status}): ${body}`,
            },
          ],
          isError: true,
        };
      }

      const data = (await res.json()) as {
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
    parameters: ScrapeParams,

    async execute(_id, params, signal, onUpdate) {
      if (!process.env.FIRECRAWL_API_KEY) {
        return {
          content: [
            { type: "text", text: "Error: FIRECRAWL_API_KEY not set." },
          ],
          isError: true,
        };
      }

      const res = await fetch("https://api.firecrawl.dev/v1/scrape", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${process.env.FIRECRAWL_API_KEY}`,
        },
        body: JSON.stringify({
          url: params.url,
          formats: ["markdown"],
        }),
        signal,
      });

      if (!res.ok) {
        const body = await res.text();
        return {
          content: [
            {
              type: "text",
              text: `Firecrawl scrape failed (${res.status}): ${body}`,
            },
          ],
          isError: true,
        };
      }

      const data = (await res.json()) as {
        data?: { markdown?: string; title?: string };
      };

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
