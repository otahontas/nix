/**
 * Pre-commit hook extension
 *
 * Runs prek checks on files after each edit/write tool call.
 * Lint failures are returned as tool result errors so the LLM
 * sees them immediately and can fix issues in the next turn.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("tool_result", async (event, ctx) => {
    if (event.toolName !== "edit" && event.toolName !== "write") {
      return;
    }

    // Don't run checks if the tool already errored
    if (event.isError) {
      return;
    }

    const path = (event.input as { path?: string }).path;
    if (!path || typeof path !== "string") {
      return;
    }

    if (ctx.hasUI) {
      ctx.ui.setStatus("pre-commit", `Checking ${path}...`);
    }

    try {
      const result = await pi.exec(
        "prek",
        ["run", "--color=never", "--files", path],
        { cwd: ctx.cwd, timeout: 30000 },
      );

      if (ctx.hasUI) {
        ctx.ui.setStatus("pre-commit", undefined);
      }

      if (result.code !== 0) {
        const output = [result.stdout, result.stderr]
          .filter(Boolean)
          .join("\n")
          .trim();

        return {
          content: [
            ...(event.content || []),
            {
              type: "text" as const,
              text: `\n\n[Pre-commit check failed for ${path}]\n${output}\n\nPlease fix the issues above.`,
            },
          ],
          isError: true,
        };
      }
    } catch {
      // Don't crash the agent if prek is unavailable
      if (ctx.hasUI) {
        ctx.ui.setStatus("pre-commit", undefined);
      }
    }
  });
}
