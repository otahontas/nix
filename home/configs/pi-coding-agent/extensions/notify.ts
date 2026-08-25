/**
 * Sends native terminal notifications with lightweight conversation context.
 * Uses OSC 777 (supported by Ghostty).
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

function collapseWhitespace(value: string): string {
  return value.replace(/\s+/g, " ").trim();
}

function sanitizeOscPart(value: string): string {
  return collapseWhitespace(
    value.replace(/[\u0000-\u001f\u007f-\u009f]/g, " ").replace(/;/g, ","),
  );
}

function notify(title: string): void {
  const safeTitle = sanitizeOscPart(title) || "Pi";
  process.stdout.write(`\x1b]777;notify;${safeTitle};done\x07`);
  process.stdout.write("\x07");
}

function canWriteNativeNotification(ctx: ExtensionContext): boolean {
  return ctx.mode === "tui" && process.stdout.isTTY;
}

export default function (pi: ExtensionAPI) {
  pi.on("agent_settled", async (_event, ctx) => {
    if (!canWriteNativeNotification(ctx)) return;

    const sessionName = pi.getSessionName();
    notify(sessionName ? `Pi: ${sessionName}` : "Pi");
  });
}
