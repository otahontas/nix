import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { readFileSync } from "node:fs";

// OAuth usage API response format
interface LimitWindow {
  utilization: number; // 0-1 percentage
  resets_at: string; // ISO timestamp
}

interface UsageLimitData {
  five_hour: LimitWindow;
  seven_day: LimitWindow;
}

export default function (pi: ExtensionAPI) {
  let cachedUsage: UsageLimitData | null = null;
  let lastFetched: number = 0;

  // Fetch and display quota when Anthropic model selected
  pi.on("model_select", async (event, ctx) => {
    if (event.model.provider !== "anthropic") {
      ctx.ui.setStatus("anthropic-quota", undefined);
      return;
    }

    const usage = await fetchAnthropicUsage();
    if (usage) {
      const sessionPercent = Math.round(usage.five_hour.utilization);
      const weeklyPercent = Math.round(usage.seven_day.utilization);

      const sessionReset = formatTimeUntil(usage.five_hour.resets_at);
      const weeklyReset = formatTimeUntil(usage.seven_day.resets_at);

      const theme = ctx.ui.theme;
      const colorPercent = (pct: number) => {
        if (pct >= 100) return theme?.fg("muted", `${pct}%`) || `${pct}%`;
        if (pct > 95) return theme?.fg("error", `${pct}%`) || `${pct}%`;
        if (pct > 85) return theme?.fg("warning", `${pct}%`) || `${pct}%`;
        return theme?.fg("success", `${pct}%`) || `${pct}%`;
      };

      const sessionLabel = theme?.fg("muted", "session: ") || "session: ";
      const weeklyLabel = theme?.fg("muted", "weekly: ") || "weekly: ";
      const separator = theme?.fg("dim", " | ") || " | ";
      const sessionTime =
        theme?.fg("dim", ` (${sessionReset})`) || ` (${sessionReset})`;
      const weeklyTime =
        theme?.fg("dim", ` (${weeklyReset})`) || ` (${weeklyReset})`;

      const status = `${sessionLabel}${colorPercent(sessionPercent)}${sessionTime}${separator}${weeklyLabel}${colorPercent(weeklyPercent)}${weeklyTime}`;

      if (sessionPercent >= 100 || weeklyPercent >= 100) {
        // No notification if quota is exhausted
      } else if (sessionPercent > 95 || weeklyPercent > 95) {
        ctx.ui.notify("Anthropic quota nearly exhausted!", "error");
      } else if (sessionPercent > 85 || weeklyPercent > 85) {
        ctx.ui.notify("Anthropic quota warning", "warning");
      }

      ctx.ui.setStatus("anthropic-quota", status);
    } else {
      ctx.ui.setStatus("anthropic-quota", undefined);
    }
  });

  // Command to check quota manually
  pi.registerCommand("anthropic-quota", {
    description: "Show Anthropic OAuth usage limits",
    handler: async (_args, ctx) => {
      // Clear cache to get fresh data
      cachedUsage = null;
      const usage = await fetchAnthropicUsage();
      if (usage) {
        const sessionPercent = Math.round(usage.five_hour.utilization);
        const weeklyPercent = Math.round(usage.seven_day.utilization);
        const sessionReset = formatTimeUntil(usage.five_hour.resets_at);
        const weeklyReset = formatTimeUntil(usage.seven_day.resets_at);

        let notifyType: "info" | "warning" | "error" = "info";
        if (sessionPercent >= 100 || weeklyPercent >= 100) {
          notifyType = "info";
        } else if (sessionPercent > 95 || weeklyPercent > 95) {
          notifyType = "error";
        } else if (sessionPercent > 85 || weeklyPercent > 85) {
          notifyType = "warning";
        }

        ctx.ui.notify(
          `Session: ${sessionPercent}% (resets in ${sessionReset})\nWeekly: ${weeklyPercent}% (resets in ${weeklyReset})`,
          notifyType,
        );
      } else {
        ctx.ui.notify(
          "Unable to fetch usage. Make sure you're logged in with OAuth.",
          "error",
        );
      }
    },
  });

  function formatTimeUntil(isoString: string): string {
    const now = Date.now();
    const reset = new Date(isoString).getTime();
    const diffMs = reset - now;

    if (diffMs <= 0) return "now";

    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffDays > 0) {
      const hours = diffHours % 24;
      return hours > 0 ? `${diffDays}d ${hours}h` : `${diffDays}d`;
    }
    if (diffHours > 0) {
      const mins = diffMins % 60;
      return mins > 0 ? `${diffHours}h ${mins}m` : `${diffHours}h`;
    }
    return `${diffMins}m`;
  }

  async function fetchAnthropicUsage(): Promise<UsageLimitData | null> {
    // Cache for 5 minutes
    const now = Date.now();
    if (cachedUsage && now - lastFetched < 5 * 60 * 1000) {
      return cachedUsage;
    }

    try {
      const authPath = `${process.env.HOME}/.pi/agent/auth.json`;
      const authData = JSON.parse(readFileSync(authPath, "utf8"));
      const anthropicAuth = authData.anthropic;
      if (!anthropicAuth?.access) return null;

      const response = await fetch(
        "https://api.anthropic.com/api/oauth/usage",
        {
          headers: {
            Authorization: `Bearer ${anthropicAuth.access}`,
            "anthropic-beta": "oauth-2025-04-20",
            "User-Agent": "claude-code/2.0.32",
            Accept: "application/json",
          },
        },
      );

      if (!response.ok) {
        console.error("OAuth usage API error:", response.status);
        return null;
      }

      cachedUsage = await response.json();
      lastFetched = now;
      return cachedUsage;
    } catch (error) {
      console.error("Failed to fetch OAuth usage:", error);
      return null;
    }
  }
}
