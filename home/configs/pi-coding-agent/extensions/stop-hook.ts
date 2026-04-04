/**
 * Stop Hook Extension
 *
 * After the agent stops, sends one follow-up asking it to verify it completed
 * everything. Resets counter on each new user prompt so every human message
 * gets at most one automatic follow-up.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const MAX_FOLLOWUPS = 1;
const STOP_CHECK_PROMPT =
  "Review your last response. Did you complete everything the user asked? If not, continue working. If you did complete everything, briefly confirm what was done.";

export default function (pi: ExtensionAPI) {
  let followupCount = 0;

  pi.on("input", async (event) => {
    if (event.source !== "extension") {
      followupCount = 0;
    }
  });

  pi.on("agent_end", async (_event, _ctx) => {
    if (followupCount >= MAX_FOLLOWUPS) return;
    followupCount++;

    pi.sendUserMessage(STOP_CHECK_PROMPT, { deliverAs: "followUp" });
  });
}
