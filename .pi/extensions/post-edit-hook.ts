/**
 * Post-edit hook extension
 *
 * Runs prek hooks on the specific file after any file-mutating tool call.
 * Injects issues into the tool result so the LLM can fix them before committing.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { join } from "node:path";

const FILE_MUTATING_TOOLS = new Set(["edit", "write"]);

export default function (pi: ExtensionAPI) {
  pi.on("tool_result", async (event, ctx) => {
    if (!FILE_MUTATING_TOOLS.has(event.toolName.toLowerCase())) return;
    if (event.isError) return;

    const input = event.input as { path?: unknown };
    const filePath = typeof input.path === "string" ? input.path : undefined;
    if (!filePath) return;

    const devenvRoot = process.env.DEVENV_ROOT ?? ctx.cwd;

    // Resolve to relative path for prek
    let relPath = filePath;
    if (filePath.startsWith(devenvRoot + "/")) {
      relPath = filePath.slice(devenvRoot.length + 1);
    }

    const result = await pi.exec(
      join(devenvRoot, ".devenv/profile/bin/prek"),
      ["run", "--files", relPath],
      {
        cwd: devenvRoot,
        signal: ctx.signal,
        timeout: 30000,
      },
    );

    if (result.code !== 0 || result.killed) {
      const output = (result.stdout || result.stderr || "").trim();
      const failures = output
        .split("\n")
        .filter((line) => line.includes("Failed"))
        .map((line) => line.trim())
        .join("\n");

      const msg = failures || output.slice(0, 500);

      ctx.ui.notify(`prek issues: ${msg.slice(0, 300)}`, "warning");

      // Inject into tool result so the LLM sees the issues and can fix them
      return {
        content: [
          ...event.content,
          {
            type: "text" as const,
            text: `⚠️ prek found issues with this file (auto-formatting may have been applied, but some checks failed):\n${msg}`,
          },
        ],
      };
    }
  });
}
