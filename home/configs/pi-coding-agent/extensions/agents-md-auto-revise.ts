/**
 * AGENTS.md Auto-Revise Extension
 *
 * Automatically prompts to update AGENTS.md with session learnings after each
 * agent turn. Ported from claude-md-management's revise-claude-md command.
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const REVISE_PROMPT = `Review this session for learnings about working in this codebase. Update AGENTS.md with context that would help future sessions be more effective.

## Step 1: Reflect

What context was missing that would have helped work more effectively?
- Bash commands that were used or discovered
- Code style patterns followed
- Testing approaches that worked
- Environment/configuration quirks
- Warnings or gotchas encountered

## Step 2: Find AGENTS.md files

\`\`\`bash
find . -name "AGENTS.md" 2>/dev/null | head -20
\`\`\`

If no AGENTS.md files exist, say so and stop. Do not create new files.

## Step 3: Draft additions

**Keep it concise** - one line per concept. AGENTS.md is part of the prompt, so brevity matters.

Format: \`<command or pattern>\` - \`<brief description>\`

Avoid:
- Verbose explanations
- Obvious information
- One-off fixes unlikely to recur

## Step 4: Show proposed changes

For each addition:

\`\`\`
### Update: ./AGENTS.md

**Why:** [one-line reason]

\`\`\`diff
+ [the addition - keep it brief]
\`\`\`
\`\`\`

## Step 5: Apply with approval

Ask if the user wants to apply the changes. Only edit files they approve.`;

export default function (pi: ExtensionAPI) {
  let lastInputSource: "interactive" | "rpc" | "extension" = "interactive";
  let skipNext = false;

  // Track input source
  pi.on("input", async (event) => {
    lastInputSource = event.source;
  });

  // On agent end, send follow-up prompt if appropriate
  pi.on("agent_end", async (_event, ctx) => {
    // Skip if last input was from extension (prevents infinite loop)
    if (lastInputSource === "extension") {
      return;
    }

    // Skip if explicitly flagged
    if (skipNext) {
      skipNext = false;
      return;
    }

    // Mark next as skipped to prevent the revise prompt from triggering itself
    skipNext = true;

    // Send user message with appropriate delivery mode
    if (ctx.isIdle()) {
      pi.sendUserMessage(REVISE_PROMPT);
    } else {
      pi.sendUserMessage(REVISE_PROMPT, { deliverAs: "followUp" });
    }
  });
}
