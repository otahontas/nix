/**
 * Copies a launch command for a cloned Pi session at the current leaf.
 */

import { spawn } from "node:child_process";
import type {
  ExtensionAPI,
  ExtensionCommandContext,
} from "@earendil-works/pi-coding-agent";
import { SessionManager } from "@earendil-works/pi-coding-agent";

function shellQuote(value: string): string {
  return `'${value.replace(/'/g, `'\\''`)}'`;
}

function copyToClipboard(text: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const child = spawn("pbcopy", { stdio: ["pipe", "ignore", "inherit"] });
    child.on("error", reject);
    child.on("close", (code) => {
      code === 0 ? resolve() : reject(new Error(`pbcopy exited with ${code}`));
    });
    child.stdin.end(text);
  });
}

export default function (pi: ExtensionAPI) {
  pi.registerCommand("clone-cmd", {
    description: "Clone current Pi branch and copy a launch command",
    handler: async (_args: string, ctx: ExtensionCommandContext) => {
      // @lat: [[home-configs#Home configs#Notable configs#clone-cmd extension]]
      try {
        await ctx.waitForIdle();

        const sessionFile = ctx.sessionManager.getSessionFile();
        const leafId = ctx.sessionManager.getLeafId();
        if (!sessionFile || !leafId) {
          throw new Error("No saved session to clone");
        }

        const clonedSession = SessionManager.open(
          sessionFile,
          ctx.sessionManager.getSessionDir(),
        );
        clonedSession.createBranchedSession(leafId);

        const command = `cd ${shellQuote(ctx.cwd)} && pi --session ${shellQuote(
          clonedSession.getSessionId(),
        )}`;
        await copyToClipboard(command);
        ctx.ui.notify(`Copied: ${command}`, "info");
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        ctx.ui.notify(`Clone command failed: ${message}`, "error");
      }
    },
  });
}
