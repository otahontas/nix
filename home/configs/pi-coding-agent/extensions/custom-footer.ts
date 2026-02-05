/**
 * Custom footer that removes cost/subscription info from the default footer.
 * Everything else matches the built-in footer behavior.
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

function sanitizeStatusText(text: string): string {
  return text
    .replace(/[\r\n\t]/g, " ")
    .replace(/ +/g, " ")
    .trim();
}

export default function (pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx) => {
    ctx.ui.setFooter((tui, theme, footerData) => {
      const unsub = footerData.onBranchChange(() => tui.requestRender());

      return {
        dispose: unsub,
        invalidate() {},
        render(width: number): string[] {
          // Calculate cumulative usage from all session entries
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

          // Context usage from API
          const contextUsage = ctx.getContextUsage();
          const contextPercentValue = contextUsage?.percent ?? 0;
          const contextWindow = contextUsage?.contextWindow ?? 0;
          const contextPercent = contextPercentValue.toFixed(1);

          // Starship prompt as first footer line
          let starshipLine: string;
          try {
            const raw = execSync(
              "starship prompt --status=0 --cmd-duration=0 --jobs=0",
              {
                cwd: ctx.cwd,
                encoding: "utf-8",
                timeout: 500,
                env: { ...process.env, TERM_PROGRAM: "ghostty" },
              },
            );
            // Strip terminal control sequences (clear screen, cursor moves, etc.)
            const cleaned = raw.replace(/\x1b\[[0-9]*[JKHG]/g, "");
            // Take first line with visible content (skip empty lines and prompt char)
            starshipLine =
              cleaned.split("\n").find((l) => visibleWidth(l) > 2) ?? "";
            // Strip leading/trailing whitespace but preserve ANSI
            starshipLine = starshipLine.replace(/^\s+/, "").replace(/\s+$/, "");
          } catch {
            // Fallback to plain cwd if starship fails
            let fallback = ctx.cwd;
            const home = process.env.HOME || process.env.USERPROFILE;
            if (home && fallback.startsWith(home)) {
              fallback = `~${fallback.slice(home.length)}`;
            }
            starshipLine = theme.fg("dim", fallback);
          }

          // Right-align session name on the starship line
          const sessionName = ctx.sessionManager.getSessionName();
          const starshipWidth = visibleWidth(starshipLine);
          if (sessionName) {
            const sessionStr = theme.fg("dim", sessionName);
            const sessionWidth = visibleWidth(sessionStr);
            const minPad = 2;
            if (starshipWidth + minPad + sessionWidth <= width) {
              const padding = " ".repeat(width - starshipWidth - sessionWidth);
              starshipLine = starshipLine + padding + sessionStr;
            } else {
              // Not enough room — truncate starship to make space
              const available = width - minPad - sessionWidth;
              if (available > 10) {
                starshipLine =
                  truncateToWidth(starshipLine, available) +
                  " ".repeat(
                    width -
                      visibleWidth(truncateToWidth(starshipLine, available)) -
                      sessionWidth,
                  ) +
                  sessionStr;
              } else {
                starshipLine = truncateToWidth(starshipLine, width);
              }
            }
          }

          const pwdColored = truncateToWidth(starshipLine, width);

          // Build stats — muted by default
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

          // Context percentage: green normally, warning >50%, error >75%
          const contextPercentDisplay = `${contextPercent}%/${formatTokens(contextWindow)}`;
          let contextPercentStr: string;
          if (contextPercentValue > 75) {
            contextPercentStr = theme.fg("error", contextPercentDisplay);
          } else if (contextPercentValue > 50) {
            contextPercentStr = theme.fg("warning", contextPercentDisplay);
          } else {
            contextPercentStr = theme.fg("success", contextPercentDisplay);
          }
          statsParts.push(contextPercentStr);

          let statsLeft = statsParts.join(" ");
          let statsLeftWidth = visibleWidth(statsLeft);

          if (statsLeftWidth > width) {
            const plain = statsLeft.replace(/\x1b\[[0-9;]*m/g, "");
            statsLeft = `${plain.substring(0, width - 3)}...`;
            statsLeftWidth = visibleWidth(statsLeft);
          }

          // Right side: provider muted, model accent, thinking level mdQuote (pink/mauve)
          const modelName = ctx.model?.id || "no-model";
          let rightSideWithoutProvider = theme.fg("accent", modelName);
          if (ctx.model?.reasoning) {
            const thinkingLevel = pi.getThinkingLevel() || "off";
            const thinkingStr =
              thinkingLevel === "off" ? "thinking off" : thinkingLevel;
            rightSideWithoutProvider =
              theme.fg("accent", modelName) +
              theme.fg("dim", " • ") +
              theme.fg("mdQuote", thinkingStr);
          }

          // Provider prefix if multiple providers
          let rightSide = rightSideWithoutProvider;
          const minPadding = 2;
          if (footerData.getAvailableProviderCount() > 1 && ctx.model) {
            const withProvider =
              theme.fg("muted", `(${ctx.model.provider}) `) +
              rightSideWithoutProvider;
            if (
              statsLeftWidth + minPadding + visibleWidth(withProvider) <=
              width
            ) {
              rightSide = withProvider;
            }
          }

          const rightSideWidth = visibleWidth(rightSide);
          const totalNeeded = statsLeftWidth + minPadding + rightSideWidth;

          let statsLine: string;
          if (totalNeeded <= width) {
            const padding = " ".repeat(width - statsLeftWidth - rightSideWidth);
            statsLine = statsLeft + padding + rightSide;
          } else {
            const availableForRight = width - statsLeftWidth - minPadding;
            if (availableForRight > 3) {
              const plainRight = rightSide.replace(/\x1b\[[0-9;]*m/g, "");
              const truncated = plainRight.substring(0, availableForRight);
              const padding = " ".repeat(
                width - statsLeftWidth - truncated.length,
              );
              statsLine = statsLeft + padding + truncated;
            } else {
              statsLine = statsLeft;
            }
          }

          // Stats already have per-part colors, just combine
          const remainder = statsLine.slice(statsLeft.length);

          const lines = [pwdColored, statsLeft + remainder];

          // Extension statuses
          const extensionStatuses = footerData.getExtensionStatuses();
          if (extensionStatuses.size > 0) {
            const statusLine = Array.from(extensionStatuses.entries())
              .sort(([a], [b]) => a.localeCompare(b))
              .map(([, text]) => sanitizeStatusText(text))
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
