/**
 * Task pipeline commands — /task, /plan, /tickets
 *
 * /task and /plan launch subagents that write their own output files.
 * The main agent just invokes the subagent and presents results.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.registerCommand("task", {
    description:
      "Research a task — launches researcher subagent that writes plans/task.md",
    handler: async (args, _ctx) => {
      if (!args || !args.trim()) {
        pi.sendUserMessage(
          [
            "Read plans/task.md if it exists and continue research.",
            "If it doesn't exist, tell the user to provide a task description: /task <description>",
          ].join("\n"),
        );
        return;
      }

      const input = args.trim();

      pi.sendUserMessage(
        [
          `Research task: ${input}`,
          "",
          "Use the subagent tool with the 'researcher' agent. The researcher will write its findings to plans/task.md.",
          "",
          "After the subagent finishes, read plans/task.md and present the findings to the user.",
        ].join("\n"),
      );
    },
  });

  pi.registerCommand("plan", {
    description:
      "Create an implementation plan — launches planner subagent that writes plans/plan.md",
    handler: async (args, _ctx) => {
      const inlineContext = args?.trim() || "";
      const contextPrefix = inlineContext
        ? `User context: ${inlineContext}\n\n`
        : "";

      pi.sendUserMessage(
        [
          "Create an implementation plan from the research findings.",
          "",
          "Read plans/task.md first — if it doesn't exist, tell the user to run /task first.",
          "",
          `Use the subagent tool with the 'planner' agent. ${inlineContext ? "Include the user context in the task. " : ""}The planner will read plans/task.md and write the plan to plans/plan.md.`,
          "",
          "After the subagent finishes, read plans/plan.md and present the plan to the user for review. Do NOT create tickets until explicitly approved.",
        ].join("\n"),
      );
    },
  });

  pi.registerCommand("tickets", {
    description:
      "Create tickets from the implementation plan using the ticket-creator skill",
    handler: async (_args, _ctx) => {
      pi.sendUserMessage(
        [
          "Create tickets from the implementation plan.",
          "",
          "Steps:",
          "1. Read plans/plan.md — if it doesn't exist, tell the user to run /plan first",
          "2. Explore the codebase for file hints and verification commands",
          "3. Seed plans/.ticket-context.md if it doesn't exist (see context seeding in ticket-creator skill)",
          "4. Create one ticket per plan step using ticket-creator skill Mode 3",
          "5. Self-validate (mandatory):",
          "   - tk list — check all tickets are open",
          "   - For each ticket: tk show <id> - verify description has file hints, acceptance criteria are numbered and independently verifiable",
          "   - Refine any weak tickets immediately",
          "   - tk dep cycle — no cycles allowed",
          "   - tk ready -T ready-for-development - at least one ticket must be unblocked; all tickets must become unblocked through the dependency chain",
          "6. Report what was created",
        ].join("\n"),
      );
    },
  });
}
