import type {
  ExtensionAPI,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";
import fs from "node:fs";
import net from "node:net";

const SOCKET_PATH = "/tmp/pi.sock";

type Payload = {
  file?: string;
  range?: [number, number];
  selection?: string;
  lsp?: {
    diagnostics?: string[];
    hover?: string;
  };
  task?: string;
};

let server: net.Server | null = null;
let latestCtx: ExtensionContext | null = null;

const formatMessage = (payload: Payload) => {
  const parts: string[] = [];

  if (payload.file) parts.push(`File: ${payload.file}`);
  if (payload.range)
    parts.push(`Lines: ${payload.range[0]}-${payload.range[1]}`);

  if (payload.selection?.trim()) {
    parts.push("Selection:");
    parts.push("```");
    parts.push(payload.selection);
    parts.push("```");
  }

  if (payload.lsp?.diagnostics?.length) {
    parts.push("LSP diagnostics:");
    for (const diag of payload.lsp.diagnostics) parts.push(`- ${diag}`);
  }

  if (payload.lsp?.hover?.trim()) {
    parts.push("LSP hover:");
    parts.push("```");
    parts.push(payload.lsp.hover);
    parts.push("```");
  }

  if (payload.task?.trim()) {
    parts.push(`Task: ${payload.task.trim()}`);
  } else {
    parts.push("Task: (not provided)");
  }

  return parts.join("\n");
};

const startServer = (pi: ExtensionAPI) => {
  if (server) return;

  if (fs.existsSync(SOCKET_PATH)) {
    try {
      fs.unlinkSync(SOCKET_PATH);
    } catch {
      // Ignore stale socket errors
    }
  }

  server = net.createServer((socket) => {
    let buffer = "";

    socket.on("data", (chunk) => {
      buffer += chunk.toString();

      let idx = buffer.indexOf("\n");
      while (idx !== -1) {
        const line = buffer.slice(0, idx).trim();
        buffer = buffer.slice(idx + 1);
        idx = buffer.indexOf("\n");

        if (!line) continue;

        try {
          const payload = JSON.parse(line) as Payload;
          const message = formatMessage(payload);
          if (!message) continue;

          const ctx = latestCtx;
          if (ctx?.isIdle()) {
            void pi.sendUserMessage(message);
          } else {
            void pi.sendUserMessage(message, { deliverAs: "followUp" });
          }
        } catch {
          // Ignore malformed payloads
        }
      }
    });
  });

  server.listen(SOCKET_PATH);
};

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    latestCtx = ctx;
    startServer(pi);

    if (ctx.hasUI) {
      ctx.ui.notify(`nvim bridge listening at ${SOCKET_PATH}`, "info");
    }
  });

  pi.on("session_switch", (_event, ctx) => {
    latestCtx = ctx;
  });

  pi.on("session_shutdown", () => {
    server?.close();
    server = null;

    if (fs.existsSync(SOCKET_PATH)) {
      try {
        fs.unlinkSync(SOCKET_PATH);
      } catch {
        // Ignore cleanup failures
      }
    }
  });
}
