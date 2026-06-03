/**
 * Coding Guardrails Extension
 *
 * Provides blocking guards for coding best practices and security.
 * All guards are inlined for simpler deployment via nix.
 */

import type {
  ExtensionAPI,
  ToolCallEvent,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

type Guard = (
  event: ToolCallEvent,
  ctx: ExtensionContext,
) => { block: true; reason: string } | undefined;

// =============================================================================
// Guards
// =============================================================================

/**
 * Block non-conventional commits
 *
 * Enforces: type(optional-scope): description
 * Valid types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
 */
const blockNonConventionalCommits: Guard = (event) => {
  if (event.toolName !== "bash") return;

  const cmd = event.input.command;
  const gitCommitPattern = /git\s+commit.*-m\s+(['"])(.+?)\1/;
  const match = cmd.match(gitCommitPattern);

  if (match) {
    const message = match[2];
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

  const cmd = event.input.command;
  const npxBunxPattern = /\b(npx|bunx)\s+/;

  if (npxBunxPattern.test(cmd)) {
    return {
      block: true,
      reason:
        "⚠️ **npx/bunx usage detected**\n\n" +
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

  const cmd = event.input.command;

  // Match rm or rmdir command:
  // - At start of line or after whitespace/semicolon/pipe/&&/||
  // - Followed by whitespace or flags
  // - Handles: rm, rm -rf, sudo rm, rmdir, sudo rmdir, etc.
  const rmPattern = /(?:^|[;&|])\s*(sudo\s+)?(rm|rmdir)(\s|$)/;

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
 * Block non-standard git worktree paths
 *
 * Enforces creating worktrees under <repo>/.worktrees/<branch>
 */
const blockNonStandardWorktreePath: Guard = (event) => {
  if (event.toolName !== "bash") return;

  const cmd = event.input.command;
  const isWorktreeAdd = /\bgit\b[^\n;|&]*\bworktree\s+add\b/.test(cmd);

  if (!isWorktreeAdd) return;

  // Accept commands that clearly target .worktrees path.
  // This also allows multi-command snippets where worktree_path is assigned earlier.
  const usesStandardPath =
    cmd.includes(".worktrees/") || cmd.includes(".worktrees\\");

  if (!usesStandardPath) {
    return {
      block: true,
      reason:
        "🌳 **Non-standard worktree path blocked**\n\n" +
        "Use the shared worktree layout for this environment:\n" +
        "- `<repo>/.worktrees/<branch>`\n\n" +
        "**What to do instead:**\n" +
        "1. `repo_root=$(git rev-parse --show-toplevel)`\n" +
        '2. `mkdir -p "$repo_root/.worktrees"`\n' +
        '3. `git worktree add "$repo_root/.worktrees/$branch" -b "$branch"`\n\n' +
        "This keeps create/cd/prune workflows consistent.",
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

  const cmd = event.input.command;

  // Match pass/gpg invocations, including absolute paths and env/sudo prefixes:
  // - pass show api/key
  // - /nix/store/.../bin/pass show api/key
  // - PATH=/tmp env FOO=bar gpg --decrypt file
  // - bash -c "/some/path/pass show api/key"
  const cmdPosition = String.raw`(^|[|&;\`'"]|\$\()`;
  const commandPrefix = String.raw`\s*(?:sudo\s+)?(?:(?:command|builtin|exec)\s+)?(?:[A-Za-z_][A-Za-z0-9_]*=\S+\s+)*(?:env\s+(?:(?:-\S+|\S+=\S+)\s+)*)?(?:(?:command|builtin|exec)\s+)?`;
  const secretProgram = String.raw`(?:[^\s'"\`;&|()]+/)?(?:pass|gpg)`;
  const commandEnd = String.raw`(?=\s|$|[;&|)'"` + "`" + String.raw`])`;
  const secretPattern = new RegExp(
    cmdPosition + commandPrefix + secretProgram + commandEnd,
  );
  const secretPathPattern = new RegExp(
    String.raw`(?:^|[\s'"` +
      "`" +
      String.raw`])(?:~|\.{1,2}|/|[^\s'"\`;&|()]+/)[^\s'"\`;&|()]*/(?:pass|gpg)` +
      commandEnd,
  );
  const envSecretPattern = new RegExp(
    cmdPosition +
      String.raw`\s*(?:sudo\s+)?env\b[^\n;&|` +
      "`" +
      String.raw`]*(?:\s|['"])(?:[^\s'"\`;&|()]+/)?(?:pass|gpg)` +
      commandEnd,
  );
  const shellExecPattern = new RegExp(
    String.raw`\b(?:bash|sh|zsh|fish)\s+-c\s+['"]?` +
      commandPrefix +
      secretProgram +
      commandEnd,
  );

  if (
    secretPattern.test(cmd) ||
    secretPathPattern.test(cmd) ||
    envSecretPattern.test(cmd) ||
    shellExecPattern.test(cmd)
  ) {
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
 * Block git commit --no-verify
 *
 * Prevents bypassing git hooks (linting, formatting, etc.).
 */
const blockNoVerifyCommit: Guard = (event) => {
  if (event.toolName !== "bash") return;

  const cmd = event.input.command;
  const gitCommitNoVerify = /\bgit\s+commit[^\n;|&]*\b(--no-verify|-n)\b/.test(
    cmd,
  );

  if (gitCommitNoVerify) {
    return {
      block: true,
      reason:
        "🚫 **git commit --no-verify blocked**\n\n" +
        "You've configured pi to never bypass git hooks.\n\n" +
        "**Why this is blocked:**\n" +
        "`--no-verify` skips pre-commit and commit-msg hooks, which enforce linting, formatting, and other quality checks.\n\n" +
        "**What to do instead:**\n" +
        "Fix the issues flagged by the hooks and commit normally.",
    };
  }
};

const guards: Guard[] = [
  blockNonConventionalCommits,
  blockNpxBunx,
  blockRmCommand,
  blockNonStandardWorktreePath,
  blockNoVerifyCommit,
  blockSecretTools,
];

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event, ctx) => {
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
