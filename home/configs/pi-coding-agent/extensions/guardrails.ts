/**
 * Coding Guardrails Extension
 *
 * Provides blocking guards for coding best practices and security.
 * All guards are inlined for simpler deployment via nix.
 */

import type {
  ExtensionAPI,
  ToolCallEvent,
  AgentResponseEvent,
  ExtensionContext,
} from "@mariozechner/pi-coding-agent";

type Guard = (
  event: ToolCallEvent | AgentResponseEvent,
  ctx: ExtensionContext,
) => { block: true; reason: string } | undefined;

// Helper to extract text from agent responses
function getResponseText(event: AgentResponseEvent): string {
  return event.response.content
    .filter((c) => c.type === "text")
    .map((c) => c.text)
    .join("\n");
}

// =============================================================================
// Guards
// =============================================================================

/**
 * Block corporate buzzwords
 *
 * Banned words: comprehensive, robust, utilize, optimize, optimized, streamline,
 * enhance, leverage, leverages, leveraging
 * Banned AI phrases: dive into, diving into, dives into
 */
const blockCorporateBuzzwords: Guard = (event) => {
  if (event.toolName !== "agent_response") return;

  const text = getResponseText(event as AgentResponseEvent);

  const buzzwordsPattern =
    /\b(comprehensive|robust|utilize|optimize|optimized|streamline|enhance|leverage|leverages|leveraging)\b/i;
  const aiPhrasesPattern = /\b(dive into|diving into|dives into)\b/i;

  if (buzzwordsPattern.test(text) || aiPhrasesPattern.test(text)) {
    return {
      block: true,
      reason:
        "⚠️ **Corporate buzzword or AI phrase detected**\n\n" +
        "You're using banned corporate speak or AI phrases.\n\n" +
        "**Banned words:** comprehensive, robust, utilize, optimize, streamline, enhance, leverage\n" +
        "**Banned AI phrases:** dive into / diving into\n\n" +
        "**Plain language alternatives:**\n" +
        "- comprehensive → complete, full, detailed\n" +
        "- robust → strong, reliable, solid\n" +
        "- utilize → use\n" +
        "- optimize → improve, make faster, tune\n" +
        "- streamline → simplify, make easier\n" +
        "- enhance → improve, make better\n" +
        "- leverage → use, take advantage of\n" +
        "- dive into → explore, look at, examine",
    };
  }
};

/**
 * Block local git config
 *
 * Prevents: git config user.name/user.email/commit.gpgsign without --global
 */
const blockLocalGitConfig: Guard = (event) => {
  if (event.toolName !== "bash") return;

  const cmd = (event as ToolCallEvent).input.command;
  const localGitConfigPattern =
    /git\s+config\s+(user\.name|user\.email|commit\.gpgsign)/;

  if (localGitConfigPattern.test(cmd) && !cmd.includes("--global")) {
    return {
      block: true,
      reason:
        "🚫 **Local git config modification blocked**\n\n" +
        "You're attempting to modify git configuration locally.\n\n" +
        "**From your AGENTS.md:**\n" +
        "> Git author/email/signing is configured globally - never set these locally per-repo\n\n" +
        "**What was blocked:**\n" +
        "- `git config user.name`\n" +
        "- `git config user.email`\n" +
        "- `git config commit.gpgsign`\n\n" +
        "**Why this matters:**\n" +
        "- Your git identity is configured globally\n" +
        "- Local overrides can cause commits to appear unverified\n" +
        "- Maintains consistency across all repositories\n\n" +
        "**If you need to change git settings:**\n" +
        'Use global config: `git config --global user.name "Your Name"`',
    };
  }
};

/**
 * Block non-conventional commits
 *
 * Enforces: type(optional-scope): description
 * Valid types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
 */
const blockNonConventionalCommits: Guard = (event) => {
  if (event.toolName !== "bash") return;

  const cmd = (event as ToolCallEvent).input.command;
  const gitCommitPattern = /git\s+commit.*-m\s+['"](.+?)['"]/;
  const match = cmd.match(gitCommitPattern);

  if (match) {
    const message = match[1];
    const conventionalPattern =
      /^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([\w-]+\))?: /;

    if (!conventionalPattern.test(message)) {
      return {
        block: true,
        reason:
          "⚠️ **Non-conventional commit message detected**\n\n" +
          "Your AGENTS.md requires conventional commits format: `type(optional-scope): description`\n\n" +
          "**Valid types:**\n" +
          "feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert\n\n" +
          "**Examples:**\n" +
          "- ✅ `feat: add dark mode toggle`\n" +
          "- ✅ `fix(auth): handle expired tokens correctly`\n" +
          "- ✅ `docs: update API documentation`\n" +
          "- ❌ `added dark mode` (wrong format)\n" +
          "- ❌ `Fix: bug` (wrong case, wrong format)\n\n" +
          "**Rules:**\n" +
          '- Use imperative mood ("add" not "added")\n' +
          "- Keep title under 72 characters\n" +
          "- No period at end of title",
      };
    }
  }
};

/**
 * Block npx/bunx usage
 *
 * Prefer package.json scripts or node_modules/.bin/
 */
const blockNpxBunx: Guard = (event) => {
  if (event.toolName !== "bash") return;

  const cmd = (event as ToolCallEvent).input.command;
  const npxBunxPattern = /\b(npx|bunx)\s+/;

  if (npxBunxPattern.test(cmd)) {
    return {
      block: true,
      reason:
        "⚠️ **npx/bunx usage detected**\n\n" +
        'Your AGENTS.md says: "Node/Deno/Bun: use package.json scripts, then node_modules/.bin/, avoid npx/bunx"\n\n' +
        "**Preferred alternatives:**\n" +
        "1. Check if there's a package.json script for this\n" +
        "2. Use `./node_modules/.bin/<command>` directly\n" +
        "3. Add a script to package.json if it's a common operation\n\n" +
        "**Why avoid npx/bunx:**\n" +
        "- Slower (downloads packages each time if not cached)\n" +
        "- Version inconsistency between runs\n" +
        "- package.json scripts are explicit and documented",
    };
  }
};

/**
 * Block rm command
 *
 * Prevents destructive file deletion. Use `trash` instead.
 */
const blockRmCommand: Guard = (event) => {
  if (event.toolName !== "bash") return;

  const cmd = (event as ToolCallEvent).input.command;

  // Match rm or rmdir command:
  // - At start of line or after whitespace/semicolon/pipe/&&/||
  // - Followed by whitespace or flags
  // - Handles: rm, rm -rf, sudo rm, rmdir, sudo rmdir, etc.
  const rmPattern = /(^|[\s;&|])(sudo\s+)?(rm|rmdir)(\s|$)/;

  if (rmPattern.test(cmd)) {
    return {
      block: true,
      reason:
        "🗑️  **Destructive `rm` command blocked**\n\n" +
        "You've configured pi to never use `rm` for file deletion.\n\n" +
        "**Why this is blocked:**\n" +
        "`rm` permanently deletes files, bypassing the trash/recycle bin. This makes it impossible to recover accidentally deleted files.\n\n" +
        "**What to do instead:**\n" +
        "Use `trash` command to safely move files to trash:\n" +
        "```bash\n" +
        "trash file.txt              # Delete single file\n" +
        "trash *.log                 # Delete multiple files\n" +
        "trash -rf directory/        # Delete directory (moves to trash)\n" +
        "```\n" +
        "Files moved to trash can be recovered from your system's trash/recycle bin if needed.",
    };
  }
};

/**
 * Block secret tools
 *
 * Prevents running commands that expose secrets (pass, gpg).
 */
const blockSecretTools: Guard = (event) => {
  if (event.toolName !== "bash") return;

  const cmd = (event as ToolCallEvent).input.command;

  // Match pass/gpg in command invocation positions:
  // - Start of line/command
  // - After | (pipe)
  // - After && or ||
  // - After ; (command separator)
  // - After $( (command substitution)
  // - After ` (backtick substitution)
  const cmdPosition = String.raw`(^|[|&;\`]|\$\()`;
  const secretPattern = new RegExp(
    cmdPosition + String.raw`\s*(pass|gpg)(\s|$)`,
  );

  if (secretPattern.test(cmd)) {
    return {
      block: true,
      reason:
        "🔒 **Secret management command blocked**\n\n" +
        "You've configured pi to never run commands that could expose secrets:\n" +
        "- `pass` (password-store)\n" +
        "- `gpg`\n\n" +
        "**Why this is blocked:**\n" +
        "Running these commands would expose your secrets in the conversation context, which is a security risk.\n\n" +
        "**What to do instead:**\n" +
        "- Run these commands manually in your terminal\n" +
        "- Use launchd agents in your nix-darwin config to generate config files from secrets\n" +
        "- Create wrapper scripts that use secrets without exposing them to pi",
    };
  }
};

/**
 * Block title case headers
 *
 * Enforces sentence case in markdown headers.
 */
const blockTitleCaseHeaders: Guard = (event) => {
  if (event.toolName !== "agent_response") return;

  const text = getResponseText(event as AgentResponseEvent);

  // Pattern matches headers with multiple title-cased words
  // Like "# Next Steps" or "## Plan Overview"
  const titleCaseHeaderPattern = /^#+\s+(?:[A-Z][a-z]*\s+)+[A-Z][a-z]+/m;

  if (titleCaseHeaderPattern.test(text)) {
    return {
      block: true,
      reason:
        "⚠️ **Title case header detected**\n\n" +
        'You\'re using title case in a header (like "Next Steps" instead of "Next steps").\n\n' +
        'Your AGENTS.md says: "Headers: always use sentence case"\n\n' +
        "Examples:\n" +
        '- ❌ "Next Steps" → ✅ "Next steps"\n' +
        '- ❌ "Plan Overview" → ✅ "Plan overview"\n' +
        '- ❌ "API Key Setup" → ✅ "API key setup"',
    };
  }
};

// =============================================================================
// Extension entry point
// =============================================================================

const guards: Guard[] = [
  blockCorporateBuzzwords,
  blockLocalGitConfig,
  blockNonConventionalCommits,
  blockNpxBunx,
  blockRmCommand,
  blockSecretTools,
  blockTitleCaseHeaders,
];

export default function (pi: ExtensionAPI) {
  const events = ["tool_call", "agent_response"] as const;

  for (const eventType of events) {
    pi.on(eventType, async (event, ctx) => {
      for (const guard of guards) {
        try {
          const result = guard(event, ctx);
          if (result?.block) {
            return result;
          }
        } catch (error) {
          console.error(`Error in guard:`, error);
        }
      }
    });
  }
}
