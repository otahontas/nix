/**
 * Stop Hook Extension
 *
 * After the agent stops, sends one follow-up asking it to verify it completed
 * everything. Resets counter on each new user prompt so every human message
 * gets at most one automatic follow-up.
 */

import { completeSimple } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const MAX_FOLLOWUPS = 1;
const STOP_CHECK_PROMPT =
  "Review your last response. Did you complete everything the user asked? If not, continue working. If you did complete everything, briefly confirm what was done.";

const LOCAL_GATEKEEPER_PROVIDER = "ollama";
const LOCAL_GATEKEEPER_MODEL_ID = "gemma4:e2b";

const CLOUD_GATEKEEPER_PROVIDER = "zai";
const CLOUD_GATEKEEPER_MODEL_ID = "glm-4.5-air";

const GATEKEEPER_PROMPT = `You are a gatekeeper that decides whether an AI coding agent should be nudged to double-check its work.

Given the last user-assistant exchange, answer YES if:
- The assistant used tools (file edits, shell commands, searches) but may not have fully completed the user's request
- The task was non-trivial and verification is worthwhile
- There are signs of incomplete work (partial changes, untested code, missing steps)

Answer NO if:
- The assistant clearly completed everything the user asked
- The work was simple and straightforward (e.g., a single file edit, a quick lookup)
- The assistant already verified its own work

Respond with only YES or NO.`;

function buildGatekeeperMessages(messages: any[]) {
  const lastUserMsg = [...messages]
    .reverse()
    .find((m: any) => m.role === "user");
  const lastAssistantMsg = [...messages]
    .reverse()
    .find((m: any) => m.role === "assistant");

  const userText = lastUserMsg?.content
    ? typeof lastUserMsg.content === "string"
      ? lastUserMsg.content
      : lastUserMsg.content
          .filter((b: any) => b.type === "text")
          .map((b: any) => b.text)
          .join("\n")
    : "(no user message)";

  const assistantText = lastAssistantMsg?.content
    ? Array.isArray(lastAssistantMsg.content)
      ? lastAssistantMsg.content
          .filter((b: any) => b.type === "text")
          .map((b: any) => b.text)
          .join("\n")
      : String(lastAssistantMsg.content)
    : "(no assistant message)";

  return [
    {
      role: "user" as const,
      content: [
        {
          type: "text" as const,
          text: `${GATEKEEPER_PROMPT}\n\nUser:\n${userText.slice(0, 4000)}\n\nAssistant:\n${assistantText.slice(0, 4000)}`,
        },
      ],
      timestamp: Date.now(),
    },
  ];
}

async function askGatekeeper(
  provider: string,
  modelId: string,
  contextMessages: any[],
  ctx: any,
): Promise<boolean | null> {
  const model = ctx.modelRegistry.find(provider, modelId);
  if (!model) return null;

  const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
  if (!auth.ok || !auth.apiKey) return null;

  const response = await completeSimple(
    model,
    { messages: contextMessages },
    {
      apiKey: auth.apiKey,
      headers: auth.headers,
      maxTokens: 16,
    },
  );

  const text = response.content
    .filter((c: any): c is { type: "text"; text: string } => c.type === "text")
    .map((c) => c.text)
    .join("")
    .trim()
    .toUpperCase();

  return !text.startsWith("NO");
}

async function shouldSendNudge(messages: any[], ctx: any): Promise<boolean> {
  const contextMessages = buildGatekeeperMessages(messages);

  // Try local gatekeeper model first
  try {
    const result = await askGatekeeper(
      LOCAL_GATEKEEPER_PROVIDER,
      LOCAL_GATEKEEPER_MODEL_ID,
      contextMessages,
      ctx,
    );
    if (result !== null) return result;
  } catch {
    // Local model unavailable, fall through to cloud
  }

  // Fall back to cloud gatekeeper model
  try {
    const result = await askGatekeeper(
      CLOUD_GATEKEEPER_PROVIDER,
      CLOUD_GATEKEEPER_MODEL_ID,
      contextMessages,
      ctx,
    );
    if (result !== null) return result;
  } catch {
    // Cloud model also unavailable, fall through to default
  }

  // Both models unavailable — nudge as safe default
  return true;
}

export default function (pi: ExtensionAPI) {
  let followupCount = 0;

  pi.on("input", async (event) => {
    if (event.source !== "extension") {
      followupCount = 0;
    }
  });

  pi.on("agent_end", async (event, _ctx) => {
    if (followupCount >= MAX_FOLLOWUPS) return;

    // Skip nudge when agent made no tool calls (simple Q&A)
    const hasToolUse = event.messages.some(
      (m: any) =>
        m.role === "assistant" &&
        Array.isArray(m.content) &&
        m.content.some((b: any) => b.type === "toolCall"),
    );
    if (!hasToolUse) return;

    // Ask gatekeeper model whether to nudge
    const shouldNudge = await shouldSendNudge(event.messages, _ctx);
    if (!shouldNudge) return;

    followupCount++;
    pi.sendUserMessage(STOP_CHECK_PROMPT, { deliverAs: "followUp" });
  });
}
