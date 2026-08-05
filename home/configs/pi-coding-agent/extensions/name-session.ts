/**
 * Names Pi sessions from the first real user prompt.
 */

import { builtinModels } from "@earendil-works/pi-ai/providers/all";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { enableFastMode } from "./fast-mode.js";

const models = builtinModels();
const TITLE_MAX_LENGTH = 64;

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

const PRESERVE_CASE_WORDS = new Set([
  "API",
  "CLI",
  "CSS",
  "HTML",
  "HTTP",
  "JSON",
  "LLM",
  "MCP",
  "Nix",
  "Pi",
  "SDK",
  "SSH",
  "TUI",
  "UI",
  "URL",
]);

const WORD_PATTERN = /[A-Za-z]+(?:[’'][A-Za-z]+)?/g;

function collapseWhitespace(value: string): string {
  return value.replace(/\s+/g, " ").trim();
}

function truncate(value: string, maxLength: number): string {
  if (value.length <= maxLength) {
    return value;
  }

  return `${value.slice(0, Math.max(0, maxLength - 1)).trimEnd()}…`;
}

function preserveCasing(word: string): boolean {
  return (
    PRESERVE_CASE_WORDS.has(word) ||
    /^[A-Z0-9]+$/.test(word) ||
    /[a-z][A-Z]/.test(word) ||
    /[A-Z][a-z]+[A-Z]/.test(word)
  );
}

function avoidTitleCase(value: string): string {
  return value.replace(WORD_PATTERN, (word) => {
    if (preserveCasing(word)) {
      return word;
    }

    if (/^[A-Z][a-z]+(?:[’'][A-Za-z]+)?$/.test(word)) {
      return word.toLowerCase();
    }

    return word;
  });
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

function buildTitlePrompt(prompt: string): string {
  return [
    "Name this Pi coding conversation.",
    "Return only a concise title: 2-6 words, no quotes, no trailing period.",
    "Use lowercase for ordinary words. Never use title case or capitalize each word.",
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

  return truncate(avoidTitleCase(title), TITLE_MAX_LENGTH - "Pi: ".length);
}

async function generateTitle(
  prompt: string,
  ctx: ExtensionContext,
): Promise<string | undefined> {
  const model = ctx.model;
  if (!model) {
    return undefined;
  }

  if (!models.getProvider(model.provider)) {
    return undefined;
  }

  const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
  if (!auth.ok || !auth.apiKey) {
    return undefined;
  }

  const response = await models.completeSimple(
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
      env: auth.env,
      maxTokens: 32,
      reasoning: "xhigh",
      onPayload: enableFastMode,
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
  let titleGenerationAttempted = false;
  let titleGenerationInFlight = false;
  let sessionGeneration = 0;
  let nextPromptFromUser = true;

  async function ensureSessionTitle(
    prompt: string,
    ctx: ExtensionContext,
  ): Promise<void> {
    if (
      !ctx.hasUI ||
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

  pi.on("session_start", async () => {
    titleGenerationInFlight = false;
    titleGenerationAttempted = Boolean(pi.getSessionName());
    sessionGeneration += 1;
    nextPromptFromUser = true;
  });

  pi.on("session_shutdown", async () => {
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
}
