/**
 * Names Pi sessions from the first real user prompt.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { enableFastMode } from "./fast-mode.js";

const TITLE_MAX_LENGTH = 64;

function collapseWhitespace(value: string): string {
  return value.replace(/\s+/g, " ").trim();
}

function truncate(value: string, maxLength: number): string {
  if (value.length <= maxLength) {
    return value;
  }

  return `${value.slice(0, Math.max(0, maxLength - 1)).trimEnd()}…`;
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

  const response = await ctx.modelRegistry.complete(
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
      maxTokens: 32,
      reasoningEffort: "xhigh",
      onPayload:
        model.provider === "openai-codex" && model.id === "gpt-5.6-sol"
          ? enableFastMode
          : undefined,
    },
  );

  const rawTitle = response.content
    .filter(
      (part: any): part is { type: "text"; text: string } =>
        part.type === "text",
    )
    .map((part: { text: string }) => part.text)
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

    if (!collapseWhitespace(prompt)) return;

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
