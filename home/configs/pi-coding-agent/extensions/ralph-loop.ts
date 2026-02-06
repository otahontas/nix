/**
 * Ralph Loop Extension
 *
 * Iterative self-referential development loop for pi. Feeds the same prompt
 * back to the agent until a completion promise is detected or max iterations
 * reached.
 *
 * Usage:
 *   /ralph-loop "Build a REST API" --max-iterations 20 --completion-promise "DONE"
 *   /cancel-ralph
 *
 * Ported from: https://github.com/anthropics/claude-plugins-official/tree/main/plugins/ralph-loop
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

interface RalphState {
  active: boolean;
  prompt: string;
  iteration: number;
  maxIterations: number; // 0 = unlimited
  completionPromise: string | null;
}

function parseArgs(argsString: string): {
  prompt: string;
  maxIterations: number;
  completionPromise: string | null;
} {
  const parts: string[] = [];
  let maxIterations = 0;
  let completionPromise: string | null = null;

  // Tokenize respecting quotes
  const tokens: string[] = [];
  let current = "";
  let inQuote: string | null = null;

  for (let i = 0; i < argsString.length; i++) {
    const ch = argsString[i];
    if (inQuote) {
      if (ch === inQuote) {
        inQuote = null;
      } else {
        current += ch;
      }
    } else if (ch === '"' || ch === "'") {
      inQuote = ch;
    } else if (ch === " " || ch === "\t") {
      if (current) {
        tokens.push(current);
        current = "";
      }
    } else {
      current += ch;
    }
  }
  if (current) tokens.push(current);

  let i = 0;
  while (i < tokens.length) {
    if (tokens[i] === "--max-iterations" && i + 1 < tokens.length) {
      const n = parseInt(tokens[i + 1], 10);
      if (isNaN(n) || n < 0) {
        throw new Error(
          `--max-iterations must be a non-negative integer, got: ${tokens[i + 1]}`,
        );
      }
      maxIterations = n;
      i += 2;
    } else if (tokens[i] === "--completion-promise" && i + 1 < tokens.length) {
      completionPromise = tokens[i + 1];
      i += 2;
    } else {
      parts.push(tokens[i]);
      i++;
    }
  }

  return {
    prompt: parts.join(" "),
    maxIterations,
    completionPromise,
  };
}

export default function (pi: ExtensionAPI) {
  const state: RalphState = {
    active: false,
    prompt: "",
    iteration: 0,
    maxIterations: 0,
    completionPromise: null,
  };

  // Track whether last input came from our extension to avoid re-triggering
  let lastInputFromExtension = false;
  let skipNextAgentEnd = false;

  pi.on("input", async (event) => {
    lastInputFromExtension = event.source === "extension";
  });

  // Register /ralph-loop command
  pi.registerCommand("ralph-loop", {
    description:
      'Start iterative Ralph loop: /ralph-loop "task" --max-iterations N --completion-promise "TEXT"',
    handler: async (args, ctx) => {
      if (!args || !args.trim()) {
        ctx.ui.notify(
          'Usage: /ralph-loop "task description" --max-iterations N --completion-promise "TEXT"',
          "error",
        );
        return;
      }

      try {
        const parsed = parseArgs(args);

        if (!parsed.prompt) {
          if (ctx.hasUI) ctx.ui.notify("Error: no prompt provided", "error");
          return;
        }

        state.active = true;
        state.prompt = parsed.prompt;
        state.iteration = 1;
        state.maxIterations = parsed.maxIterations;
        state.completionPromise = parsed.completionPromise;

        const maxDisplay =
          state.maxIterations > 0 ? `${state.maxIterations}` : "unlimited";
        const promiseDisplay = state.completionPromise ?? "none";

        if (ctx.hasUI) {
          ctx.ui.notify(
            `🔄 Ralph loop activated! Iteration: 1, Max: ${maxDisplay}, Promise: ${promiseDisplay}`,
            "info",
          );
          ctx.ui.setStatus(
            "ralph-loop",
            `🔄 Ralph #${state.iteration}/${maxDisplay}`,
          );
        }

        // Send the initial prompt
        skipNextAgentEnd = false;
        pi.sendUserMessage(buildPrompt(state));
      } catch (e: any) {
        if (ctx.hasUI) ctx.ui.notify(`Error: ${e.message}`, "error");
      }
    },
  });

  // Register /cancel-ralph command
  pi.registerCommand("cancel-ralph", {
    description: "Cancel active Ralph loop",
    handler: async (_args, ctx) => {
      if (!state.active) {
        if (ctx.hasUI) ctx.ui.notify("No active Ralph loop found.", "info");
        return;
      }

      const iteration = state.iteration;
      state.active = false;
      state.prompt = "";
      state.iteration = 0;
      state.maxIterations = 0;
      state.completionPromise = null;
      if (ctx.hasUI) {
        ctx.ui.setStatus("ralph-loop", undefined);
        ctx.ui.notify(
          `🛑 Cancelled Ralph loop (was at iteration ${iteration})`,
          "info",
        );
      }
    },
  });

  // After agent finishes, check if we should continue the loop
  pi.on("agent_end", async (event, ctx) => {
    if (!state.active) return;

    // Skip if this agent_end is from the initial command setup
    if (skipNextAgentEnd) {
      skipNextAgentEnd = false;
      return;
    }

    // Only act on extension-sourced messages (our own loop messages)
    // On first iteration, the input comes from the command handler
    if (!lastInputFromExtension && state.iteration > 1) return;

    // Check completion promise in last assistant message
    if (state.completionPromise) {
      const lastAssistantText = getLastAssistantText(event.messages);
      if (
        lastAssistantText &&
        checkPromise(lastAssistantText, state.completionPromise)
      ) {
        if (ctx.hasUI) {
          ctx.ui.notify(
            `✅ Ralph loop: completion promise detected after ${state.iteration} iterations`,
            "info",
          );
          ctx.ui.setStatus("ralph-loop", undefined);
        }
        state.active = false;
        return;
      }
    }

    // Check max iterations
    if (state.maxIterations > 0 && state.iteration >= state.maxIterations) {
      if (ctx.hasUI) {
        ctx.ui.notify(
          `🛑 Ralph loop: max iterations (${state.maxIterations}) reached`,
          "info",
        );
        ctx.ui.setStatus("ralph-loop", undefined);
      }
      state.active = false;
      return;
    }

    // Continue loop: increment and re-send prompt
    state.iteration++;
    const maxDisplay = state.maxIterations > 0 ? `${state.maxIterations}` : "∞";
    if (ctx.hasUI) {
      ctx.ui.setStatus(
        "ralph-loop",
        `🔄 Ralph #${state.iteration}/${maxDisplay}`,
      );
    }

    pi.sendUserMessage(buildPrompt(state));
  });
}

function buildPrompt(state: RalphState): string {
  const maxDisplay =
    state.maxIterations > 0 ? `${state.maxIterations}` : "unlimited";
  let header = `🔄 Ralph iteration ${state.iteration}/${maxDisplay}`;

  if (state.completionPromise) {
    header += `\nTo complete this loop, output: <promise>${state.completionPromise}</promise> (ONLY when the statement is genuinely TRUE)`;
  } else {
    header +=
      "\nNo completion promise set — loop runs until max iterations or /cancel-ralph";
  }

  return `${header}\n\n${state.prompt}`;
}

function getLastAssistantText(messages: any[]): string | null {
  if (!messages || messages.length === 0) return null;

  // Walk backwards to find the last assistant message
  for (let i = messages.length - 1; i >= 0; i--) {
    const msg = messages[i];
    if (msg.role === "assistant" && msg.content) {
      if (typeof msg.content === "string") return msg.content;
      if (Array.isArray(msg.content)) {
        const textParts = msg.content
          .filter((p: any) => p.type === "text")
          .map((p: any) => p.text);
        if (textParts.length > 0) return textParts.join("\n");
      }
    }
  }

  return null;
}

function checkPromise(text: string, promise: string): boolean {
  // Look for <promise>TEXT</promise> in the output
  const match = text.match(/<promise>([\s\S]*?)<\/promise>/);
  if (!match) return false;

  // Normalize whitespace for comparison
  const found = match[1].trim().replace(/\s+/g, " ");
  const expected = promise.trim().replace(/\s+/g, " ");

  return found === expected;
}
