/**
 * Double Shot Latte - Auto-continuation extension
 *
 * Port of https://github.com/obra/double-shot-latte
 * Automatically evaluates whether the agent should continue working
 * instead of stopping prematurely.
 *
 * Key principle: If you can type "continue" and the agent knows what to do,
 * this extension continues automatically.
 */

import type {
  ExtensionAPI,
  ExtensionContext,
  AgentEndEvent,
} from "@mariozechner/pi-coding-agent";

interface ThrottleState {
  count: number;
  lastTime: number;
}

interface ContinuationJudgment {
  should_continue: boolean;
  reasoning: string;
}

// Configuration
const MAX_CONTINUATIONS = 3;
const THROTTLE_WINDOW_MS = 5 * 60 * 1000; // 5 minutes
const JUDGE_MODEL = process.env.DOUBLE_SHOT_LATTE_MODEL || "haiku";

export default function (pi: ExtensionAPI) {
  // Track continuation attempts per session
  let throttleState: ThrottleState = { count: 0, lastTime: 0 };
  let isJudging = false;

  // Reset throttle on session start
  pi.on("session_start", async () => {
    throttleState = { count: 0, lastTime: 0 };
    isJudging = false;
  });

  // Evaluate continuation at the end of each agent response
  pi.on("agent_end", async (event: AgentEndEvent, ctx: ExtensionContext) => {
    // Skip if we're in the middle of judging (prevent recursion)
    if (isJudging) return;

    // Skip if no UI (print mode, etc.)
    if (!ctx.hasUI) return;

    // Check throttling
    const now = Date.now();
    const timeSinceLast = now - throttleState.lastTime;

    // Reset counter if window has passed
    if (timeSinceLast > THROTTLE_WINDOW_MS) {
      throttleState = { count: 0, lastTime: now };
    }

    // Force stop if we've hit the limit
    if (throttleState.count >= MAX_CONTINUATIONS) {
      ctx.ui.notify(
        `Auto-continue: max ${MAX_CONTINUATIONS} continuations reached, stopping`,
        "info",
      );
      throttleState = { count: 0, lastTime: 0 };
      return;
    }

    // Get recent conversation context
    const entries = ctx.sessionManager.getBranch();
    const recentMessages = entries.slice(-10);

    if (recentMessages.length === 0) return;

    // Build context for the judge
    const contextText = recentMessages
      .map((entry) => {
        if (entry.type === "message") {
          const msg = entry.message;
          if (msg.role === "user") {
            const text = msg.content
              .filter((c) => c.type === "text")
              .map((c) => c.text)
              .join("\n");
            return `USER: ${text}`;
          }
          if (msg.role === "assistant") {
            const text = msg.content
              .filter((c) => c.type === "text")
              .map((c) => c.text)
              .join("\n");
            return `ASSISTANT: ${text}`;
          }
        }
        return null;
      })
      .filter(Boolean)
      .join("\n\n");

    // Evaluate continuation
    const judgment = await evaluateContinuation(pi, ctx, contextText);

    if (judgment?.should_continue) {
      // Update throttle state
      throttleState.count++;
      throttleState.lastTime = now;

      ctx.ui.notify(
        `Auto-continue (${throttleState.count}/${MAX_CONTINUATIONS}): ${truncate(judgment.reasoning, 50)}`,
        "info",
      );

      // Send continuation message
      pi.sendUserMessage("continue", { deliverAs: "followUp" });
    }
  });

  /**
   * Use Claude to evaluate whether continuation is appropriate
   */
  async function evaluateContinuation(
    pi: ExtensionAPI,
    ctx: ExtensionContext,
    contextText: string,
  ): Promise<ContinuationJudgment | null> {
    isJudging = true;

    try {
      const prompt = buildEvaluationPrompt(contextText);

      // Use claude CLI to evaluate (separate instance, no recursion risk)
      const result = await pi.exec(
        "claude",
        [
          "--print",
          "--model",
          JUDGE_MODEL,
          "--output-format",
          "json",
          "--json-schema",
          JSON.stringify({
            type: "object",
            properties: {
              should_continue: { type: "boolean" },
              reasoning: { type: "string" },
            },
            required: ["should_continue", "reasoning"],
          }),
          "--system-prompt",
          "You are a conversation state classifier. Your only job is to analyze conversation transcripts and determine if the assistant has more autonomous work to do. You output structured JSON. You do not write code or use tools.",
          "--disallowedTools",
          "*",
          prompt,
        ],
        { timeout: 30000 },
      );

      if (result.code !== 0) {
        console.error("Claude evaluation failed:", result.stderr);
        return null;
      }

      // Parse the response
      const response = JSON.parse(result.stdout);
      const structuredOutput = response.structured_output;

      if (!structuredOutput) {
        console.error("No structured output from Claude");
        return null;
      }

      return structuredOutput as ContinuationJudgment;
    } catch (error) {
      console.error("Continuation evaluation error:", error);
      return null;
    } finally {
      isJudging = false;
    }
  }
}

function buildEvaluationPrompt(contextText: string): string {
  return `Analyze this conversation and determine: Does the assistant have more autonomous work to do RIGHT NOW?

Conversation:
${contextText}

CONTINUE (should_continue: true) ONLY IF the assistant explicitly states what it will do next:
- Phrases indicating intent to continue (e.g., 'Next I need to...', 'Now I'll...', 'Moving on to...')
- Incomplete todo list with remaining items marked pending
- Stated follow-up tasks not yet performed

STOP (should_continue: false) in ALL other cases:

1. TASK COMPLETION - The assistant indicates work is finished:
   - Completion statements (done, complete, finished, ready, all set)
   - Summary of accomplished work with no stated next steps
   - Confirming something is working/verified/installed

2. QUESTIONS - The assistant needs user input:
   - Asking for approval, decisions, clarification, or confirmation
   - Offering optional actions (e.g., 'Want me to...?', 'Should I also...?')
   - Note: Mid-task continuation questions (e.g., 'Should I continue?' when work is ongoing) = CONTINUE

3. BLOCKERS - The assistant cannot proceed:
   - Unresolved errors or missing information
   - Uncertainty about requirements

KEY: If the assistant is WAITING for the user (whether after completing work OR asking a question), that means STOP. Waiting ≠ more autonomous work to do.

Default to STOP when uncertain.`;
}

function truncate(text: string, maxLen: number): string {
  if (text.length <= maxLen) return text;
  return text.slice(0, maxLen - 3) + "...";
}
