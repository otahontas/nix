/**
 * Sends native terminal notifications with lightweight conversation context.
 * Uses OSC 777 (supported by Ghostty).
 */

import { completeSimple } from "@earendil-works/pi-ai";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

const TITLE_MAX_LENGTH = 64;
const BODY_MAX_LENGTH = 160;
const COMMAND_MAX_LENGTH = 96;
const NOTIFICATION_DELAY_MS = 75;
const NOTIFICATION_RETRY_MS = 250;
const NOTIFICATION_MAX_RETRIES = 40;
const STOP_HOOK_CHECK_START_EVENT = "otahontas.stop-hook.check-start";
const STOP_HOOK_CHECK_END_EVENT = "otahontas.stop-hook.check-end";

const GREETING_WORDS = new Set([
  "ahoy",
  "cool",
  "hello",
  "hey",
  "hi",
  "hola",
  "jou",
  "jouu",
  "lol",
  "nice",
  "ok",
  "okay",
  "sup",
  "thanks",
  "thx",
  "yo",
  "yollooo",
]);

const TASK_VERBS = [
  "add",
  "audit",
  "build",
  "change",
  "check",
  "create",
  "debug",
  "explain",
  "fix",
  "help",
  "implement",
  "inspect",
  "investigate",
  "plan",
  "refactor",
  "remove",
  "review",
  "run",
  "suggest",
  "test",
  "update",
  "write",
];

const NEEDS_INPUT_PATTERNS = [
  /\?\s*$/,
  /\bblocked (until|on)\b/i,
  /\bcannot continue without\b/i,
  /\bchoose (one|an option|which)\b/i,
  /\bneed (your )?(input|confirmation|approval|choice)\b/i,
  /\bplease (confirm|choose|provide)\b/i,
  /\bwhat should\b/i,
  /\bwhich (one|option|approach|path)\b/i,
];

type ContentBlock = {
  type?: string;
  text?: string;
};

type MessageLike = {
  role?: string;
  content?: unknown;
};

function collapseWhitespace(value: string): string {
  return value.replace(/\s+/g, " ").trim();
}

function truncate(value: string, maxLength: number): string {
  if (value.length <= maxLength) {
    return value;
  }

  return `${value.slice(0, Math.max(0, maxLength - 1)).trimEnd()}…`;
}

function sanitizeOscPart(value: string, maxLength: number): string {
  return truncate(
    collapseWhitespace(
      value.replace(/[\u0000-\u001f\u007f-\u009f]/g, " ").replace(/;/g, ","),
    ),
    maxLength,
  );
}

function notify(title: string, body: string): void {
  const safeTitle = sanitizeOscPart(title, TITLE_MAX_LENGTH) || "Pi";
  const safeBody = sanitizeOscPart(body, BODY_MAX_LENGTH) || "done";
  process.stdout.write(`\x1b]777;notify;${safeTitle};${safeBody}\x07`);
}

function getCliMode(): string | undefined {
  const modeArg = process.argv.find((arg) => arg.startsWith("--mode="));
  if (modeArg) {
    return modeArg.slice("--mode=".length);
  }

  const modeIndex = process.argv.indexOf("--mode");
  if (modeIndex >= 0) {
    return process.argv[modeIndex + 1];
  }

  return undefined;
}

function canWriteNativeNotification(ctx: ExtensionContext): boolean {
  if (!ctx.hasUI || !process.stdout.isTTY) {
    return false;
  }

  const mode = getCliMode();
  if (mode && mode !== "interactive") {
    return false;
  }

  return !process.argv.some(
    (arg) => arg === "-p" || arg === "--print" || arg === "--json",
  );
}

function extractTextParts(content: unknown): string[] {
  if (typeof content === "string") {
    return [content];
  }

  if (!Array.isArray(content)) {
    return [];
  }

  const parts: string[] = [];
  for (const part of content) {
    if (!part || typeof part !== "object") {
      continue;
    }

    const block = part as ContentBlock;
    if (block.type === "text" && typeof block.text === "string") {
      parts.push(block.text);
    }
  }

  return parts;
}

function extractFinalAssistantText(messages: unknown[]): string {
  for (let index = messages.length - 1; index >= 0; index--) {
    const message = messages[index] as MessageLike;
    if (message?.role !== "assistant") {
      continue;
    }

    const text = extractTextParts(message.content).join("\n").trim();
    if (text) {
      return text;
    }
  }

  return "";
}

function formatCommand(command: string): string {
  return truncate(collapseWhitespace(command), COMMAND_MAX_LENGTH);
}

function looksLikeRealTask(prompt: string): boolean {
  const text = collapseWhitespace(prompt).toLowerCase();
  if (!text) {
    return false;
  }

  if (text.includes("?")) {
    return true;
  }

  const words = text.match(/[a-z0-9]+/g) ?? [];
  if (words.length > 0 && words.every((word) => GREETING_WORDS.has(word))) {
    return false;
  }

  if (text.length <= 16 && !words.some((word) => TASK_VERBS.includes(word))) {
    return false;
  }

  return text.length > 48 || words.some((word) => TASK_VERBS.includes(word));
}

function looksLikeNeedsInput(finalAssistantText: string): boolean {
  const text = finalAssistantText.trim();
  return (
    text.length > 0 &&
    NEEDS_INPUT_PATTERNS.some((pattern) => pattern.test(text))
  );
}

function buildNotificationBody(
  finalAssistantText: string,
  failedBashCommand: string | undefined,
): string {
  if (failedBashCommand) {
    return `command failed: ${formatCommand(failedBashCommand)}`;
  }

  if (looksLikeNeedsInput(finalAssistantText)) {
    return "needs input";
  }

  return "done";
}

function buildTitlePrompt(prompt: string): string {
  return [
    "Name this Pi coding conversation.",
    "Return only a concise title: 2-6 words, no quotes, no trailing period.",
    "Return EMPTY if the input is only a greeting, thanks, acknowledgement, or test message.",
    "Focus on the user's concrete task.",
    "",
    "<user_input>",
    prompt,
    "</user_input>",
  ].join("\n");
}

function cleanGeneratedTitle(value: string): string | undefined {
  const title = collapseWhitespace(
    value
      .split("\n")[0]
      ?.replace(/^title:\s*/i, "")
      .replace(/^["'`]+|["'`.!?]+$/g, "") ?? "",
  );

  if (!title || title.toUpperCase() === "EMPTY") {
    return undefined;
  }

  return truncate(title, TITLE_MAX_LENGTH - "Pi: ".length);
}

async function generateTitle(
  prompt: string,
  ctx: ExtensionContext,
): Promise<string | undefined> {
  const model = ctx.model;
  if (!model) {
    return undefined;
  }

  const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
  if (!auth.ok || !auth.apiKey) {
    return undefined;
  }

  const response = await completeSimple(
    model,
    {
      messages: [
        {
          role: "user" as const,
          content: [{ type: "text" as const, text: buildTitlePrompt(prompt) }],
          timestamp: Date.now(),
        },
      ],
    },
    {
      apiKey: auth.apiKey,
      headers: auth.headers,
      maxTokens: 32,
    },
  );

  const rawTitle = response.content
    .filter(
      (part): part is { type: "text"; text: string } => part.type === "text",
    )
    .map((part) => part.text)
    .join("\n");

  return cleanGeneratedTitle(rawTitle);
}

export default function (pi: ExtensionAPI) {
  let failedBashCommand: string | undefined;
  let titleGenerationAttempted = false;
  let titleGenerationInFlight = false;
  let sessionGeneration = 0;
  let agentRunGeneration = 0;
  let nextPromptFromUser = true;
  let stopHookChecksInFlight = 0;

  async function ensureSessionTitle(
    prompt: string,
    ctx: ExtensionContext,
  ): Promise<void> {
    if (
      !canWriteNativeNotification(ctx) ||
      pi.getSessionName() ||
      titleGenerationAttempted ||
      titleGenerationInFlight
    ) {
      return;
    }

    if (!looksLikeRealTask(prompt)) {
      return;
    }

    titleGenerationAttempted = true;
    titleGenerationInFlight = true;

    const generation = sessionGeneration;
    const sessionFile = ctx.sessionManager.getSessionFile();

    try {
      const title = await generateTitle(prompt, ctx);
      if (!title) {
        return;
      }

      if (
        generation !== sessionGeneration ||
        ctx.sessionManager.getSessionFile() !== sessionFile ||
        pi.getSessionName()
      ) {
        return;
      }

      pi.setSessionName(title);
    } catch {
      // Title generation is best effort. Never break the agent loop.
    } finally {
      titleGenerationInFlight = false;
    }
  }

  function notificationTitle(): string {
    const sessionName = pi.getSessionName();
    return sessionName ? `Pi: ${sessionName}` : "Pi";
  }

  const cleanupStopHookStart = pi.events.on(STOP_HOOK_CHECK_START_EVENT, () => {
    stopHookChecksInFlight += 1;
  });

  const cleanupStopHookEnd = pi.events.on(STOP_HOOK_CHECK_END_EVENT, () => {
    stopHookChecksInFlight = Math.max(0, stopHookChecksInFlight - 1);
  });

  pi.on("session_start", async () => {
    failedBashCommand = undefined;
    titleGenerationInFlight = false;
    titleGenerationAttempted = Boolean(pi.getSessionName());
    sessionGeneration += 1;
    nextPromptFromUser = true;
  });

  pi.on("session_shutdown", async () => {
    cleanupStopHookStart();
    cleanupStopHookEnd();
    sessionGeneration += 1;
  });

  pi.on("input", async (event) => {
    nextPromptFromUser = event.source !== "extension";
  });

  pi.on("before_agent_start", async (event, ctx) => {
    const shouldNameFromThisPrompt = nextPromptFromUser;
    nextPromptFromUser = false;

    if (shouldNameFromThisPrompt) {
      await ensureSessionTitle(event.prompt, ctx);
    }
  });

  pi.on("agent_start", async () => {
    failedBashCommand = undefined;
    agentRunGeneration += 1;
  });

  pi.on("tool_result", async (event) => {
    if (event.toolName !== "bash" || !event.isError) {
      return;
    }

    const command = event.input.command;
    if (typeof command === "string" && command.trim()) {
      failedBashCommand = command;
    }
  });

  pi.on("agent_end", async (event, ctx) => {
    if (!canWriteNativeNotification(ctx)) {
      return;
    }

    const body = buildNotificationBody(
      extractFinalAssistantText(event.messages),
      failedBashCommand,
    );
    const generation = sessionGeneration;
    const runGeneration = agentRunGeneration;
    const sessionFile = ctx.sessionManager.getSessionFile();

    const maybeNotify = (retriesLeft: number) => {
      if (
        generation !== sessionGeneration ||
        runGeneration !== agentRunGeneration ||
        ctx.sessionManager.getSessionFile() !== sessionFile ||
        !canWriteNativeNotification(ctx)
      ) {
        return;
      }

      if (stopHookChecksInFlight > 0) {
        if (retriesLeft > 0) {
          setTimeout(() => maybeNotify(retriesLeft - 1), NOTIFICATION_RETRY_MS);
        }
        return;
      }

      if (!ctx.isIdle() || ctx.hasPendingMessages()) {
        return;
      }

      notify(notificationTitle(), body);
    };

    setTimeout(
      () => maybeNotify(NOTIFICATION_MAX_RETRIES),
      NOTIFICATION_DELAY_MS,
    );
  });
}
