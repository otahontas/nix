/**
 * Custom footer that removes cost/subscription info from the default footer
 * and uses starship prompt instead of plain cwd.
 */

import type { AssistantMessage } from "@mariozechner/pi-ai";
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@mariozechner/pi-tui";
import { execSync } from "node:child_process";

function formatTokens(count: number): string {
  if (count < 1000) return count.toString();
  if (count < 10000) return `${(count / 1000).toFixed(1)}k`;
  if (count < 1000000) return `${Math.round(count / 1000)}k`;
  if (count < 10000000) return `${(count / 1000000).toFixed(1)}M`;
  return `${Math.round(count / 1000000)}M`;
}

function rightAlign(
  left: string,
  right: string,
  width: number,
  minPad = 2,
): string {
  const leftW = visibleWidth(left);
  const rightW = visibleWidth(right);
  if (leftW + minPad + rightW <= width) {
    return left + " ".repeat(width - leftW - rightW) + right;
  }
  const available = width - leftW - minPad;
  if (available > 3) {
    const truncRight = truncateToWidth(right, available);
    const truncRightW = visibleWidth(truncRight);
    return left + " ".repeat(width - leftW - truncRightW) + truncRight;
  }
  return left;
}

function getStarshipLine(cwd: string, dim: (s: string) => string): string {
  try {
    const raw = execSync(
      "starship prompt --status=0 --cmd-duration=0 --jobs=0",
      {
        cwd,
        encoding: "utf-8",
        timeout: 500,
        env: { ...process.env, TERM_PROGRAM: "ghostty" },
      },
    );
    const cleaned = raw.replace(/\x1b\[[0-9]*[JKHG]/g, "");
    const line = cleaned.split("\n").find((l) => visibleWidth(l) > 2) ?? "";
    return line.replace(/^\s+/, "").replace(/\s+$/, "");
  } catch {
    let fallback = cwd;
    const home = process.env.HOME || process.env.USERPROFILE;
    if (home && fallback.startsWith(home)) {
      fallback = `~${fallback.slice(home.length)}`;
    }
    return dim(fallback);
  }
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    ctx.ui.setFooter((tui, theme, footerData) => {
      const unsub = footerData.onBranchChange(() => tui.requestRender());

      return {
        dispose: unsub,
        invalidate() {},
        render(width: number): string[] {
          // Cumulative usage from all session entries
          let totalInput = 0;
          let totalOutput = 0;
          let totalCacheRead = 0;
          let totalCacheWrite = 0;

          for (const entry of ctx.sessionManager.getEntries()) {
            if (
              entry.type === "message" &&
              entry.message.role === "assistant"
            ) {
              const m = entry.message as AssistantMessage;
              totalInput += m.usage.input;
              totalOutput += m.usage.output;
              totalCacheRead += m.usage.cacheRead;
              totalCacheWrite += m.usage.cacheWrite;
            }
          }

          // Line 1: starship prompt with session name right-aligned
          const starship = getStarshipLine(ctx.cwd, (s) => theme.fg("dim", s));
          const sessionName = ctx.sessionManager.getSessionName();
          const line1 = sessionName
            ? rightAlign(starship, theme.fg("dim", sessionName), width)
            : starship;

          // Line 2 left: token stats + context usage
          const contextUsage = ctx.getContextUsage();
          const contextPct = contextUsage?.percent ?? 0;
          const contextWindow = contextUsage?.contextWindow ?? 0;

          const statsParts: string[] = [];
          if (totalInput)
            statsParts.push(theme.fg("muted", `↑${formatTokens(totalInput)}`));
          if (totalOutput)
            statsParts.push(theme.fg("muted", `↓${formatTokens(totalOutput)}`));
          if (totalCacheRead)
            statsParts.push(
              theme.fg("muted", `R${formatTokens(totalCacheRead)}`),
            );
          if (totalCacheWrite)
            statsParts.push(
              theme.fg("muted", `W${formatTokens(totalCacheWrite)}`),
            );

          const contextDisplay = `${contextPct.toFixed(1)}%/${formatTokens(contextWindow)}`;
          const contextColor =
            contextPct > 75 ? "error" : contextPct > 50 ? "warning" : "success";
          statsParts.push(theme.fg(contextColor, contextDisplay));

          let statsLeft = statsParts.join(" ");
          if (visibleWidth(statsLeft) > width) {
            statsLeft = truncateToWidth(statsLeft, width, "...");
          }

          // Line 2 right: model + thinking level
          const modelName = ctx.model?.id || "no-model";
          let rightSide = theme.fg("accent", modelName);
          if (ctx.model?.reasoning) {
            const level = pi.getThinkingLevel() || "off";
            rightSide +=
              theme.fg("dim", " • ") +
              theme.fg("mdQuote", level === "off" ? "thinking off" : level);
          }

          // Prepend provider if multiple available
          if (footerData.getAvailableProviderCount() > 1 && ctx.model) {
            const withProvider =
              theme.fg("muted", `(${ctx.model.provider}) `) + rightSide;
            if (
              visibleWidth(statsLeft) + 2 + visibleWidth(withProvider) <=
              width
            ) {
              rightSide = withProvider;
            }
          }

          const lines = [
            truncateToWidth(line1, width),
            rightAlign(statsLeft, rightSide, width),
          ];

          // Extension statuses
          const extensionStatuses = footerData.getExtensionStatuses();
          if (extensionStatuses.size > 0) {
            const statusLine = Array.from(extensionStatuses.entries())
              .sort(([a], [b]) => a.localeCompare(b))
              .map(([, text]) =>
                text
                  .replace(/[\r\n\t]/g, " ")
                  .replace(/ +/g, " ")
                  .trim(),
              )
              .join(" ");
            lines.push(
              truncateToWidth(statusLine, width, theme.fg("dim", "...")),
            );
          }

          return lines;
        },
      };
    });
  });
}
