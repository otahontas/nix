/**
 * Task pipeline commands — /task and /plan backed by subagents
 *
 * These commands orchestrate the research → plan → tickets → work pipeline.
 * Research and planning phases use the subagent tool to run in isolated processes
 * with restricted tool access (read-only, no file mutations).
 *
 * The main agent's only job during /task and /plan is:
 *   1. Create/manage worktrees
 *   2. Invoke the subagent tool
 *   3. Save subagent output to plans/*.md files
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("task", {
    description:
      "Research a task using an isolated subagent (read-only, no mutations)",
    handler: async (args, ctx) => {
      if (!args || !args.trim()) {
        ctx.ui.notify("Usage: /task <description> or /task <slug>", "warning");
        return;
      }

      const input = args.trim();

      // Derive slug from input: lowercase, hyphens, short
      const deriveSlug = (text: string): string => {
        // If it looks like an existing slug (short, no spaces), use as-is
        if (
          /^[a-z0-9-]+$/.test(text) &&
          text.length <= 40 &&
          !text.includes("  ")
        ) {
          return text;
        }
        return text
          .toLowerCase()
          .replace(/[^a-z0-9\s-]/g, "")
          .replace(/\s+/g, "-")
          .replace(/-+/g, "-")
          .replace(/^-|-$/g, "")
          .split("-")
          .slice(0, 4)
          .join("-");
      };

      const slug = deriveSlug(input);

      // Send message to agent with clear instructions
      pi.sendUserMessage(
        [
          `Research task: ${input}`,
          `Slug: ${slug}`,
          "",
          "Use the subagent tool with the 'researcher' agent to research this task in an isolated process.",
          "",
          "Steps:",
          `1. Create a worktree at .worktrees/${slug} if it doesn't exist (branch: ${slug})`,
          `2. If plans/${slug}.md already exists, read it first, then pass its contents as context`,
          `3. Call subagent tool: { agent: "researcher", task: "<the research task with all context>" }`,
          `4. Save the subagent output to plans/${slug}.md`,
          "",
          "The researcher agent runs in isolation — it can read files, search code, and run read-only commands, but CANNOT edit, write, or modify anything.",
          "Its output will be the research findings. Save that output verbatim to the plans file.",
        ].join("\n"),
      );
    },
  });

  pi.registerCommand("plan", {
    description:
      "Create an implementation plan using an isolated subagent (read-only)",
    handler: async (args, ctx) => {
      if (!args || !args.trim()) {
        ctx.ui.notify("Usage: /plan <slug>", "warning");
        return;
      }

      const slug = args
        .trim()
        .toLowerCase()
        .replace(/[^a-z0-9-]/g, "");

      pi.sendUserMessage(
        [
          `Create implementation plan for slug: ${slug}`,
          "",
          "Use the subagent tool with the 'planner' agent to create an implementation plan.",
          "",
          "Steps:",
          `1. Read plans/${slug}.md (the research findings) — if it doesn't exist, tell the user to run /task first`,
          `2. Call subagent tool: { agent: "planner", task: "<the research findings from plans/${slug}.md>" }`,
          `3. Save the subagent output to plans/${slug}.plan.md`,
          "",
          "The planner agent runs in isolation — it can read files but CANNOT edit or write anything.",
          "Its output will be the implementation plan. Save that output verbatim to the plans file.",
          "Present the plan to the user for review. Do NOT create tickets until explicitly approved.",
        ].join("\n"),
      );
    },
  });
}
