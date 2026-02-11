import * as fs from "node:fs";
import * as path from "node:path";
import { complete } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

function findNearestAgentsMd(startDir: string): string | null {
  let dir = path.resolve(startDir);
  const root = path.parse(dir).root;

  while (true) {
    const candidate = path.join(dir, "AGENTS.md");
    if (fs.existsSync(candidate)) {
      return candidate;
    }
    if (dir === root) return null;
    dir = path.dirname(dir);
  }
}

function buildConversationText(entries: any[]): string {
  const sections: string[] = [];

  for (const entry of entries) {
    if (entry.type !== "message" || !entry.message?.role) continue;

    const role = entry.message.role;
    if (role !== "user" && role !== "assistant") continue;

    const content = entry.message.content;
    const texts: string[] = [];

    if (typeof content === "string") {
      texts.push(content);
    } else if (Array.isArray(content)) {
      for (const part of content) {
        if (part?.type === "text" && typeof part.text === "string") {
          texts.push(part.text);
        }
      }
    }

    const joined = texts.join("\n").trim();
    if (joined) {
      sections.push(`${role === "user" ? "User" : "Assistant"}: ${joined}`);
    }
  }

  return sections.join("\n\n");
}

const MAX_CONVERSATION_CHARS = 80_000;

function truncateConversation(text: string): string {
  if (text.length <= MAX_CONVERSATION_CHARS) return text;
  // Keep the end (most recent messages are most relevant)
  return (
    "[...earlier conversation truncated...]\n\n" +
    text.slice(text.length - MAX_CONVERSATION_CHARS)
  );
}

const EXTRACTION_PROMPT = `You are reviewing a coding session to extract learnings for a project's AGENTS.md file.

AGENTS.md provides instructions and context that coding agents read at the start of every session. It should contain non-obvious, project-specific knowledge — not generic advice.

Given the conversation below and the current AGENTS.md content, identify learnings worth persisting. Focus on:

- Gotchas, quirks, or non-obvious constraints discovered
- Commands or workflows that worked (build, test, deploy specifics)
- Code conventions followed or corrected
- Error patterns and their actual solutions
- Environment or configuration quirks

Rules:
- Output ONLY bullet points (lines starting with "- "), one learning per line
- Each line must be concise and actionable — one line, no sub-bullets
- Do NOT repeat anything already in AGENTS.md
- Do NOT include generic advice, obvious things, or one-off fixes unlikely to recur
- If nothing worth adding was discovered, output exactly: NO_UPDATES`;

export default function (pi: ExtensionAPI) {
  pi.registerCommand("learn", {
    description: "Extract session learnings and propose AGENTS.md updates",
    handler: async (_args, ctx) => {
      const branch = ctx.sessionManager.getBranch();
      const conversationText = buildConversationText(branch);

      if (!conversationText.trim()) {
        ctx.ui.notify("No conversation to analyze.", "warning");
        return;
      }

      const targetFile = findNearestAgentsMd(ctx.cwd);
      if (!targetFile) {
        ctx.ui.notify(
          "No AGENTS.md found in current directory or parents.",
          "warning",
        );
        return;
      }

      const model = ctx.model;
      if (!model) {
        ctx.ui.notify("No model configured.", "error");
        return;
      }

      const apiKey = await ctx.modelRegistry.getApiKey(model);
      if (!apiKey) {
        ctx.ui.notify(`No API key for current model.`, "error");
        return;
      }

      const currentContent = fs.readFileSync(targetFile, "utf-8");
      const truncated = truncateConversation(conversationText);

      const userMessage = `${EXTRACTION_PROMPT}

<agents-md path="${targetFile}">
${currentContent}
</agents-md>

<conversation>
${truncated}
</conversation>`;

      ctx.ui.notify("Analyzing session for learnings...", "info");

      try {
        const response = await complete(
          model,
          {
            messages: [
              {
                role: "user",
                content: [{ type: "text", text: userMessage }],
                timestamp: Date.now(),
              },
            ],
          },
          { apiKey, reasoningEffort: "medium" },
        );

        const responseText = response.content
          .filter((c): c is { type: "text"; text: string } => c.type === "text")
          .map((c) => c.text)
          .join("\n")
          .trim();

        if (!responseText || responseText === "NO_UPDATES") {
          ctx.ui.notify("No new learnings identified.", "info");
          return;
        }

        // Filter to only bullet point lines
        const bullets = responseText
          .split("\n")
          .map((l) => l.trim())
          .filter((l) => l.startsWith("- "));

        if (bullets.length === 0) {
          ctx.ui.notify("No new learnings identified.", "info");
          return;
        }

        // Show all proposed changes in an editor for the user to curate
        const edited = await ctx.ui.editor(
          `Proposed additions to ${path.basename(targetFile)} (delete lines you don't want, then confirm):`,
          bullets.join("\n"),
        );

        if (typeof edited !== "string" || !edited.trim()) {
          ctx.ui.notify("No updates applied.", "info");
          return;
        }

        const finalLines = edited
          .split("\n")
          .map((l) => l.trim())
          .filter((l) => l.length > 0);

        if (finalLines.length === 0) {
          ctx.ui.notify("No updates applied.", "info");
          return;
        }

        const ok = await ctx.ui.confirm(
          `Apply ${finalLines.length} addition(s) to ${targetFile}?`,
          finalLines.join("\n"),
        );

        if (!ok) {
          ctx.ui.notify("Cancelled.", "info");
          return;
        }

        // Append with a blank line separator
        const separator = currentContent.endsWith("\n\n")
          ? ""
          : currentContent.endsWith("\n")
            ? "\n"
            : "\n\n";
        const addition = finalLines.join("\n") + "\n";
        fs.writeFileSync(
          targetFile,
          currentContent + separator + addition,
          "utf-8",
        );

        ctx.ui.notify(
          `Added ${finalLines.length} line(s) to ${targetFile}`,
          "info",
        );
      } catch (error: any) {
        console.error("Learn command failed:", error);
        ctx.ui.notify(
          `Failed to extract learnings: ${error?.message ?? "unknown error"}`,
          "error",
        );
      }
    },
  });
}
