import { Type } from "typebox";
import {
  getMarkdownTheme,
  keyHint,
  type ExtensionAPI,
  type Theme,
} from "@earendil-works/pi-coding-agent";
import { Box, Markdown, Text } from "@earendil-works/pi-tui";

const PREVIEW_LINES = 4;

function collapsibleResult(
  result: { content: Array<{ type: string; text?: string }> },
  options: { expanded: boolean; isPartial: boolean },
  theme: Theme,
) {
  const text = result.content?.[0]?.type === "text" ? (result.content[0] as { type: "text"; text: string }).text : "";
  if (!text) return new Text(theme.fg("dim", "(empty)"), 0, 0);
  if (options.isPartial) return new Text(theme.fg("dim", "…"), 0, 0);
  const mdTheme = getMarkdownTheme();
  if (options.expanded) return new Markdown(text, 0, 0, mdTheme);

  const lines = text.split("\n");
  if (lines.length <= PREVIEW_LINES) return new Markdown(text, 0, 0, mdTheme);

  const preview = lines.slice(0, PREVIEW_LINES).join("\n");
  const remaining = lines.length - PREVIEW_LINES;
  const hint = keyHint("app.tools.expand", "to expand");
  return new Text(
    preview + "\n" +
    theme.fg("dim", `… ${remaining} more lines (${hint})`),
    0, 0,
  );
}

/** Absolute path to the lat binary, injected by `lat init`. */
const LAT = "lat";

async function run(
  pi: ExtensionAPI,
  args: string[],
  cwd: string,
  signal?: AbortSignal,
): Promise<string> {
  const result = await pi.exec(LAT, args, { cwd, signal, timeout: 30_000 });
  if (result.code !== 0 || result.killed) {
    throw new Error(result.stdout || result.stderr || "lat command failed");
  }
  return result.stdout;
}

async function tryRun(
  pi: ExtensionAPI,
  args: string[],
  cwd: string,
  signal?: AbortSignal,
): Promise<string> {
  try {
    return await run(pi, args, cwd, signal);
  } catch {
    return "";
  }
}

function customMessageText(content: string | unknown[]): string {
  if (typeof content === "string") return content;

  return content
    .map((part) => typeof part === "string" ? part : JSON.stringify(part))
    .join("\n");
}

export default function (pi: ExtensionAPI) {
  // ── Tools ──────────────────────────────────────────────────────────

  pi.registerTool({
    name: "lat_search",
    label: "lat search",
    description: "Semantic search across lat.md sections using embeddings",
    promptSnippet: "Search lat.md documentation by meaning",
    promptGuidelines: [
      "Use before starting any task to find relevant design context",
      "Search results include section IDs you can pass to lat_section",
    ],
    parameters: Type.Object({
      query: Type.String({ description: "Search query in natural language" }),
      limit: Type.Optional(
        Type.Number({ description: "Max results (default 5)", default: 5 }),
      ),
    }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      const args = ["search", params.query];
      if (params.limit) args.push("--limit", String(params.limit));
      const output = await tryRun(pi, args, ctx.cwd, signal);
      return {
        content: [{ type: "text", text: output || "No results found." }],
        details: {},
      };
    },
    renderCall(args, theme) {
      return new Text(
        theme.fg("toolTitle", theme.bold("lat search ")) +
        theme.fg("dim", `"${args.query}"`),
        0, 0,
      );
    },
    renderResult: collapsibleResult,
  });

  pi.registerTool({
    name: "lat_section",
    label: "lat section",
    description:
      "Show full content of a lat.md section with outgoing/incoming refs",
    promptSnippet: "Read a specific lat.md section",
    parameters: Type.Object({
      query: Type.String({
        description:
          'Section ID or name (e.g. "cli#init", "Tests#User login")',
      }),
    }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      const output = await tryRun(pi, ["section", params.query], ctx.cwd, signal);
      return {
        content: [
          { type: "text", text: output || "Section not found." },
        ],
        details: {},
      };
    },
    renderCall(args, theme) {
      return new Text(
        theme.fg("toolTitle", theme.bold("lat section ")) +
        theme.fg("dim", `"${args.query}"`),
        0, 0,
      );
    },
    renderResult: collapsibleResult,
  });

  pi.registerTool({
    name: "lat_locate",
    label: "lat locate",
    description:
      "Find a section by name (exact, subsection tail, or fuzzy match)",
    promptSnippet: "Find a lat.md section by name",
    parameters: Type.Object({
      query: Type.String({ description: "Section name to locate" }),
    }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      const output = await tryRun(pi, ["locate", params.query], ctx.cwd, signal);
      return {
        content: [
          { type: "text", text: output || "No sections matching query." },
        ],
        details: {},
      };
    },
    renderCall(args, theme) {
      return new Text(
        theme.fg("toolTitle", theme.bold("lat locate ")) +
        theme.fg("dim", `"${args.query}"`),
        0, 0,
      );
    },
  });

  pi.registerTool({
    name: "lat_check",
    label: "lat check",
    description:
      "Validate all wiki links and code refs in lat.md. Returns errors or 'All checks passed'",
    promptSnippet: "Validate lat.md links and code refs",
    parameters: Type.Object({}),
    async execute(_id, _params, signal, _onUpdate, ctx) {
      try {
        const output = await run(pi, ["check"], ctx.cwd, signal);
        return { content: [{ type: "text", text: output }], details: {} };
      } catch (error) {
        throw new Error(error instanceof Error ? error.message : "Check failed");
      }
    },
    renderCall(_args, theme) {
      return new Text(
        theme.fg("toolTitle", theme.bold("lat check")),
        0, 0,
      );
    },
  });

  pi.registerTool({
    name: "lat_expand",
    label: "lat expand",
    description:
      "Expand [[refs]] in text to resolved file locations and context",
    promptSnippet: "Resolve [[wiki links]] in text",
    parameters: Type.Object({
      text: Type.String({ description: "Text containing [[refs]] to expand" }),
    }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      const output = await tryRun(pi, ["expand", params.text], ctx.cwd, signal);
      return {
        content: [{ type: "text", text: output || params.text }],
        details: {},
      };
    },
    renderCall(args, theme) {
      const preview = args.text.length > 60 ? args.text.slice(0, 60) + "…" : args.text;
      return new Text(
        theme.fg("toolTitle", theme.bold("lat expand ")) +
        theme.fg("dim", `"${preview}"`),
        0, 0,
      );
    },
  });

  pi.registerTool({
    name: "lat_refs",
    label: "lat refs",
    description: "Find what references a given section",
    promptSnippet: "Find incoming references to a lat.md section",
    parameters: Type.Object({
      query: Type.String({
        description: 'Section ID (e.g. "cli#init", "file#Section")',
      }),
    }),
    async execute(_id, params, signal, _onUpdate, ctx) {
      const output = await tryRun(pi, ["refs", params.query], ctx.cwd, signal);
      return {
        content: [{ type: "text", text: output || "No references found." }],
        details: {},
      };
    },
    renderCall(args, theme) {
      return new Text(
        theme.fg("toolTitle", theme.bold("lat refs ")) +
        theme.fg("dim", `"${args.query}"`),
        0, 0,
      );
    },
  });

  // ── Message renderers ────────────────────────────────────────────

  pi.registerMessageRenderer("lat-reminder", (message, { expanded, outputPad }, theme) => {
    const content = customMessageText(message.content);
    const box = new Box(outputPad, 1, (t) => theme.bg("customMessageBg", t));
    if (expanded) {
      box.addChild(new Text(theme.fg("accent", "lat.md"), 0, 0));
      box.addChild(new Markdown(content, 0, 0, getMarkdownTheme()));
    } else {
      const hint = keyHint("app.tools.expand", "to expand");
      box.addChild(new Text(
        theme.fg("accent", "lat.md") + " " +
        theme.fg("dim", `Search lat.md before starting work. Keep lat.md/ in sync. (${hint})`),
        0, 0,
      ));
    }
    return box;
  });

  pi.registerMessageRenderer("lat-check", (message, { expanded, outputPad }, theme) => {
    const content = customMessageText(message.content);
    const box = new Box(outputPad, 1, (t) => theme.bg("customMessageBg", t));
    if (expanded) {
      box.addChild(new Text(theme.fg("warning", "lat check"), 0, 0));
      box.addChild(new Markdown(content, 0, 0, getMarkdownTheme()));
    } else {
      const hint = keyHint("app.tools.expand", "to expand");
      const firstLine = content.split("\n")[0];
      box.addChild(new Text(
        theme.fg("warning", "lat check") + " " +
        theme.fg("dim", `${firstLine} (${hint})`),
        0, 0,
      ));
    }
    return box;
  });

  // ── Lifecycle hooks ────────────────────────────────────────────────

  // Guard to prevent agent_end from firing twice per prompt (infinite loop)
  let agentEndFired = false;

  pi.on("before_agent_start", async () => {
    agentEndFired = false;

    const reminder = [
      "Before starting work, run `lat_search` with one or more queries describing the user's intent.",
      "ALWAYS do this, even when the task seems straightforward — search results may reveal critical design details, protocols, or constraints.",
      "Use `lat_section` to read the full content of relevant matches.",
      "Do not read files, write code, or run commands until you have searched.",
      "",
      "Remember: `lat.md/` must stay in sync with the codebase. If you change code, update the relevant sections in `lat.md/` and run `lat_check` before finishing.",
    ].join("\n");

    return {
      message: {
        customType: "lat-reminder",
        content: reminder,
        display: true,
      },
    };
  });

  pi.on("agent_end", async (_event, ctx) => {
    // Don't fire twice per prompt — prevents infinite loop
    if (agentEndFired) return;
    agentEndFired = true;

    // Run lat check
    let checkFailed = false;
    try {
      await run(pi, ["check"], ctx.cwd);
    } catch {
      checkFailed = true;
    }

    // Run git diff --numstat to check if lat.md/ is in sync
    let needsSync = false;
    let codeLines = 0;
    try {
      const result = await pi.exec("git", ["diff", "HEAD", "--numstat"], {
        cwd: ctx.cwd,
      });
      if (result.code !== 0) throw new Error(result.stderr);
      const numstat = result.stdout;

      let latMdLines = 0;
      for (const line of numstat.split("\n")) {
        const parts = line.split("\t");
        if (parts.length < 3) continue;
        const added = parseInt(parts[0], 10) || 0;
        const removed = parseInt(parts[1], 10) || 0;
        const file = parts[2];
        const changed = added + removed;
        if (file.startsWith("lat.md/")) {
          latMdLines += changed;
        } else if (/\.(ts|tsx|js|jsx|py|rs|go|c|h)$/.test(file)) {
          codeLines += changed;
        }
      }

      if (codeLines >= 5) {
        const effectiveLatMd = latMdLines === 0 ? 0 : Math.max(latMdLines, 1);
        needsSync = effectiveLatMd < codeLines * 0.05;
      }
    } catch {
      // git not available or no HEAD — skip diff check
    }

    if (!checkFailed && !needsSync) return;

    const parts: string[] = [];
    if (checkFailed && needsSync) {
      parts.push(
        `\`lat check\` found errors AND the codebase has changes (${codeLines} lines) with no updates to \`lat.md/\`. Before finishing:`,
        "",
        "1. Update `lat.md/` to reflect your code changes — run `lat_search` to find relevant sections.",
        "2. Run `lat_check` until it passes.",
      );
    } else if (checkFailed) {
      parts.push(
        "`lat check` failed. Run `lat_check`, fix the errors, and repeat until it passes.",
      );
    } else {
      parts.push(
        `The codebase has changes (${codeLines} lines) but \`lat.md/\` was not updated. Update \`lat.md/\` to be in sync with the changes — run \`lat_search\` to find relevant sections. Run \`lat_check\` at the end.`,
      );
    }

    pi.sendMessage(
      { customType: "lat-check", content: parts.join("\n"), display: true },
      { deliverAs: "followUp", triggerTurn: true },
    );
  });
}
