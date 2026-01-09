/**
 * Coding Guardrails Extension
 *
 * Provides blocking and warning guards for coding best practices and security.
 * Converted from the original hookify hooks used in Claude Code setup.
 *
 * Blocking guards:
 * - block-secret-tools: Prevent running commands that expose secrets
 * - block-local-git-config: Prevent local git config modifications
 * - block-claude-attribution: Prevent AI attribution in commits
 * - block-pr-claude-attribution: Prevent AI attribution in PRs
 * - protect-pi-dir: Prevent modifications to .pi/ directory
 *
 * Warning guards:
 * - warn-corporate-buzzwords: Detect corporate speak and AI phrases
 * - warn-title-case-headers: Detect title case in markdown headers
 * - warn-npx-bunx: Warn against npx/bunx usage
 * - warn-conventional-commits: Warn about non-conventional commit messages
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  // ========================================================================
  // BLOCKING GUARDS
  // ========================================================================

  /**
   * Block secret tools: Prevent running commands that expose secrets
   * Blocks: pass, op (1Password CLI), gpg --decrypt
   */
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return;

    const cmd = event.input.command as string;
    const secretPattern = /(^|\s)(pass|op|gpg\s+(--decrypt|-d))(\s|$)/;

    if (secretPattern.test(cmd)) {
      return {
        block: true,
        reason:
          "🔒 **Secret management command blocked**\n\n" +
          "You've configured pi to never run commands that could expose secrets:\n" +
          "- `pass` (password-store)\n" +
          "- `op` (1Password CLI)\n" +
          "- `gpg --decrypt` / `gpg -d` (GPG decryption)\n\n" +
          "**Why this is blocked:**\n" +
          "Running these commands would expose your secrets in the conversation context, which is a security risk.\n\n" +
          "**What to do instead:**\n" +
          "- Run these commands manually in your terminal\n" +
          "- Use launchd agents in your nix-darwin config to generate config files from secrets\n" +
          "- Create wrapper scripts that use secrets without exposing them to pi",
      };
    }
  });

  /**
   * Block local git config: Prevent local repository git config modifications
   * Blocks: git config user.name, user.email, commit.gpgsign (without --global)
   */
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return;

    const cmd = event.input.command as string;
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
  });

  /**
   * Block Claude attribution: Prevent AI attribution in git commits
   * Blocks commit messages with "Generated with" or "Co-Authored-By: Claude"
   */
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return;

    const cmd = event.input.command as string;
    const gitCommitPattern = /git\s+commit/;
    const attributionPattern = /(🤖 Generated with|Co-Authored-By: Claude)/;

    if (gitCommitPattern.test(cmd) && attributionPattern.test(cmd)) {
      return {
        block: true,
        reason:
          "🚫 **Claude attribution detected in commit message**\n\n" +
          "Your commit message contains Claude Code attribution that you've explicitly requested to exclude.\n\n" +
          "**Detected pattern:**\n" +
          "- `🤖 Generated with [Claude Code]`\n" +
          "- `Co-Authored-By: Claude <noreply@anthropic.com>`\n\n" +
          "**From your AGENTS.md:**\n" +
          "- No AI attribution\n" +
          "- No co-author credits\n\n" +
          "**What to do:**\n" +
          "Remove the attribution lines from the commit message and try again.",
      };
    }
  });

  /**
   * Block PR Claude attribution: Prevent AI attribution in GitHub PRs
   * Blocks PR creation with "Generated with" or "Co-Authored-By: Claude"
   */
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash") return;

    const cmd = event.input.command as string;
    const ghPrPattern = /gh\s+pr\s+create/;
    const attributionPattern = /(🤖 Generated with|Co-Authored-By: Claude)/;

    if (ghPrPattern.test(cmd) && attributionPattern.test(cmd)) {
      return {
        block: true,
        reason:
          "🚫 **Claude attribution detected in PR body**\n\n" +
          "Your PR body contains Claude Code attribution that you've explicitly requested to exclude.\n\n" +
          "**Detected pattern:**\n" +
          "- `🤖 Generated with [Claude Code]`\n" +
          "- `Co-Authored-By: Claude <noreply@anthropic.com>`\n\n" +
          "**From your AGENTS.md:**\n" +
          "- No AI attribution\n" +
          "- No co-author credits\n\n" +
          "**What to do:**\n" +
          "Remove the attribution lines from the PR body and try again.",
      };
    }
  });

  /**
   * Protect .pi/ directory: Prevent modifications to pi configuration
   * Blocks write and edit operations to .pi/ directory
   */
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "write" && event.toolName !== "edit") return;

    const path = event.input.path as string;

    if (path.includes("/.pi/") || path.startsWith(".pi/")) {
      if (ctx.hasUI) {
        ctx.ui.notify(
          `Blocked modification to .pi/ directory: ${path}`,
          "warning",
        );
      }
      return {
        block: true,
        reason:
          "**BLOCKED: Modification to .pi/ directory**\n\n" +
          "You are NOT allowed to modify files in the `.pi/` directory.\n\n" +
          "If changes are needed, ask the user to make the modification themselves.",
      };
    }
  });

  // ========================================================================
  // WARNING GUARDS
  // ========================================================================

  /**
   * Warn about corporate buzzwords: Detect corporate speak and AI phrases in responses
   * Warns about: comprehensive, robust, utilize, optimize, streamline, enhance, leverage, dive into
   */
  pi.on("agent_response", async (event, ctx) => {
    if (!ctx.hasUI) return;

    const text = event.response.content
      .filter((c) => c.type === "text")
      .map((c) => c.text)
      .join(" ");

    const buzzwordsPattern =
      /\b(comprehensive|robust|utilize|optimize|optimized|streamline|enhance|leverage|leverages|leveraging)\b/i;
    const aiPhrasesPattern = /\b(dive into|diving into|dives into)\b/i;

    if (buzzwordsPattern.test(text) || aiPhrasesPattern.test(text)) {
      ctx.ui.notify(
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
        "warning",
      );
    }
  });

  /**
   * Warn about title case headers: Detect title case in markdown headers
   * Warns about headers like "Next Steps" instead of "Next steps"
   */
  pi.on("agent_response", async (event, ctx) => {
    if (!ctx.hasUI) return;

    const text = event.response.content
      .filter((c) => c.type === "text")
      .map((c) => c.text)
      .join("\n");

    // Pattern matches headers with multiple title-cased words
    // Like "# Next Steps" or "## Plan Overview"
    const titleCaseHeaderPattern = /^#+\s+(?:[A-Z][a-z]*\s+)+[A-Z][a-z]+/m;

    if (titleCaseHeaderPattern.test(text)) {
      ctx.ui.notify(
        "⚠️ **Title case header detected**\n\n" +
          'You\'re using title case in a header (like "Next Steps" instead of "Next steps").\n\n' +
          'Your AGENTS.md says: "Headers: always use sentence case"\n\n' +
          "Examples:\n" +
          '- ❌ "Next Steps" → ✅ "Next steps"\n' +
          '- ❌ "Plan Overview" → ✅ "Plan overview"\n' +
          '- ❌ "API Key Setup" → ✅ "API key setup"',
        "warning",
      );
    }
  });

  /**
   * Warn about npx/bunx usage: Prefer package.json scripts or node_modules/.bin/
   */
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash" || !ctx.hasUI) return;

    const cmd = event.input.command as string;
    const npxBunxPattern = /\b(npx|bunx)\s+/;

    if (npxBunxPattern.test(cmd)) {
      ctx.ui.notify(
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
        "warning",
      );
    }
  });

  /**
   * Warn about non-conventional commits: Enforce conventional commit format
   * Warns when commit message doesn't follow: type(scope): description
   */
  pi.on("tool_call", async (event, ctx) => {
    if (event.toolName !== "bash" || !ctx.hasUI) return;

    const cmd = event.input.command as string;
    const gitCommitPattern = /git\s+commit.*-m\s+['"](.+?)['"]/;
    const match = cmd.match(gitCommitPattern);

    if (match) {
      const message = match[1];
      const conventionalPattern =
        /^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([\w-]+\))?: /;

      if (!conventionalPattern.test(message)) {
        ctx.ui.notify(
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
          "warning",
        );
      }
    }
  });
}
