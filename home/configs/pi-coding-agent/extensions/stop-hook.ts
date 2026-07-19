/**
 * Stop Hook Extension
 *
 * After the agent stops, sends one follow-up asking it to verify it completed
 * everything. Resets counter on each new user prompt so every human message
 * gets at most one automatic follow-up.
 */

import type { SimpleStreamOptions } from "@earendil-works/pi-ai";
import { builtinModels } from "@earendil-works/pi-ai/providers/all";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

const models = builtinModels();
const MAX_FOLLOWUPS = 1;
const STOP_HOOK_CHECK_START_EVENT = "otahontas.stop-hook.check-start";
const STOP_HOOK_CHECK_END_EVENT = "otahontas.stop-hook.check-end";
const STOP_CHECK_PROMPT =
  "Review your last response. Did you complete everything the user asked? If not, continue working only within the user's requested scope. If the user only asked you to investigate, inspect, check, audit, or report findings, do not fix anything now; report findings and ask before changing anything. If you did complete everything, briefly confirm what was done.";

const MAX_GATEKEEPER_FAILURES = 3;

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

const PAIRS_TO_SEND = 3;

function extractText(content: unknown): string {
  if (typeof content === "string") return content;
  if (Array.isArray(content))
    return content
      .filter((b: any) => b.type === "text")
      .map((b: any) => b.text)
      .join("\n");
  return "";
}

function buildGatekeeperMessages(messages: any[]) {
  // Single reverse pass: collect last N user-assistant pairs
  const collected: { role: string; content: unknown }[] = [];
  let pairCount = 0;

  for (let i = messages.length - 1; i >= 0 && pairCount < PAIRS_TO_SEND; i--) {
    const m = messages[i];
    if (m.role !== "user" && m.role !== "assistant") continue;
    collected.unshift(m);
    if (m.role === "user") pairCount++;
  }

  const text = collected
    .map((m) => {
      const label = m.role === "user" ? "User" : "Assistant";
      return `${label}:\n${extractText(m.content)}`;
    })
    .join("\n\n");

  return [
    {
      role: "user" as const,
      content: [
        {
          type: "text" as const,
          text: `${GATEKEEPER_PROMPT}\n\n${text}`,
        },
      ],
      timestamp: Date.now(),
    },
  ];
}

async function askGatekeeper(
  contextMessages: any[],
  ctx: ExtensionContext,
  thinkingLevel: ReturnType<ExtensionAPI["getThinkingLevel"]>,
): Promise<boolean | null> {
  const model = ctx.model;
  if (!model) return null;

  if (!models.getProvider(model.provider)) return null;

  const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
  if (!auth.ok || !auth.apiKey) return null;

  const options: SimpleStreamOptions = {
    apiKey: auth.apiKey,
    headers: auth.headers,
    env: auth.env,
    maxTokens: 16,
  };
  if (thinkingLevel !== "off") {
    options.reasoning = thinkingLevel;
  }

  const response = await models.completeSimple(
    model,
    { messages: contextMessages },
    options,
  );

  const text = response.content
    .filter((c: any): c is { type: "text"; text: string } => c.type === "text")
    .map((c) => c.text)
    .join("")
    .trim()
    .toUpperCase();

  return !text.startsWith("NO");
}

// Quick heuristic: skip gatekeeper for obvious completions
function looksComplete(messages: any[]): boolean {
  const lastAssistant = [...messages]
    .reverse()
    .find((m: any) => m.role === "assistant");
  if (!lastAssistant) return false;

  const text = extractText(lastAssistant.content).toLowerCase();

  // Check for completion signals in the assistant's response
  const completionSignals = [
    /\ball (changes|tasks|steps) (applied|done|complete|committed)\b/,
    /\bverification passed\b/,
    /\ball tests? (pass|passed)\b/,
  ];

  return completionSignals.some((re) => re.test(text));
}

async function shouldSendNudge(
  messages: any[],
  ctx: ExtensionContext,
  thinkingLevel: ReturnType<ExtensionAPI["getThinkingLevel"]>,
  failureCounter: { count: number },
): Promise<boolean> {
  // Skip gatekeeper if too many consecutive failures
  if (failureCounter.count >= MAX_GATEKEEPER_FAILURES) return false;

  // Quick heuristic: skip for obvious completions
  if (looksComplete(messages)) return false;

  const contextMessages = buildGatekeeperMessages(messages);

  // Ask the same model and thinking level Pi is using for this session.
  try {
    const result = await askGatekeeper(contextMessages, ctx, thinkingLevel);
    if (result !== null) {
      failureCounter.count = 0;
      return result;
    }
  } catch {
    failureCounter.count++;
    return false;
  }

  // Default model unavailable — don't nudge without informed decision
  failureCounter.count++;
  return false;
}

export default function (pi: ExtensionAPI) {
  let followupCount = 0;
  const gatekeeperFailures = { count: 0 };

  pi.on("input", async (event) => {
    if (event.source !== "extension") {
      followupCount = 0;
    }
  });

  pi.on("agent_end", async (event, ctx) => {
    if (followupCount >= MAX_FOLLOWUPS) return;

    // Skip nudge when agent made no tool calls (simple Q&A)
    const hasToolUse = event.messages.some(
      (m: any) =>
        m.role === "assistant" &&
        Array.isArray(m.content) &&
        m.content.some((b: any) => b.type === "toolCall"),
    );
    if (!hasToolUse) return;

    pi.events.emit(STOP_HOOK_CHECK_START_EVENT, undefined);
    try {
      // Ask gatekeeper model whether to nudge
      const shouldNudge = await shouldSendNudge(
        event.messages,
        ctx,
        pi.getThinkingLevel(),
        gatekeeperFailures,
      );
      if (!shouldNudge) return;

      followupCount++;
      pi.sendUserMessage(STOP_CHECK_PROMPT, { deliverAs: "followUp" });
    } finally {
      pi.events.emit(STOP_HOOK_CHECK_END_EVENT, undefined);
    }
  });
}
