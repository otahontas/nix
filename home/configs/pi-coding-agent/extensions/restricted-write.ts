/**
 * Restricted write tools for subagents.
 *
 * Provides `write-task` and `write-plan` tools that only allow writing
 * to plans/task.md and plans/plan.md respectively. Used by researcher
 * and planner agents instead of the unrestricted `write` tool.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import * as path from "node:path";
import * as fs from "node:fs";

const WriteParams = Type.Object({
  content: Type.String({ description: "Content to write to the file" }),
});

function makeRestrictedWriter(fileName: string, label: string) {
  return {
    name: `write-${label}`,
    label: `Write ${fileName}`,
    description: `Write content to plans/${fileName}. This is the ONLY file this tool can write to.`,
    promptSnippet: `Write research findings to plans/${fileName}`,
    promptGuidelines: [
      `Use this tool to write your output to plans/${fileName}. No other file writes are available.`,
    ],
    parameters: WriteParams,
    async execute(
      _toolCallId: string,
      params: { content: string },
      _signal: AbortSignal,
      _onUpdate: unknown,
      ctx: { cwd: string },
    ) {
      const targetPath = path.join(ctx.cwd, "plans", fileName);
      const dir = path.dirname(targetPath);

      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }

      // Resolve to absolute and verify it lands inside plans/
      const resolved = path.resolve(targetPath);
      const plansDir = path.resolve(path.join(ctx.cwd, "plans"));
      if (!resolved.startsWith(plansDir + path.sep) && resolved !== plansDir) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Error: cannot write outside plans/. Resolved path: ${resolved}`,
            },
          ],
          isError: true,
        };
      }

      fs.writeFileSync(resolved, params.content, "utf-8");
      const lines = params.content.split("\n").length;

      return {
        content: [
          {
            type: "text" as const,
            text: `Wrote ${lines} lines to plans/${fileName}`,
          },
        ],
      };
    },
  };
}

export default function (pi: ExtensionAPI) {
  pi.registerTool(makeRestrictedWriter("task.md", "task"));
  pi.registerTool(makeRestrictedWriter("plan.md", "plan"));
}
