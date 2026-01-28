import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { Buffer } from "node:buffer";
import { readFileSync } from "node:fs";

// Anthropic OAuth usage API response format
interface LimitWindow {
  utilization: number; // 0-1 percentage
  resets_at: string; // ISO timestamp
}

interface UsageLimitData {
  five_hour: LimitWindow;
  seven_day: LimitWindow;
}

// OpenAI Codex (ChatGPT subscription) usage endpoint format
// GET https://chatgpt.com/backend-api/wham/usage
interface CodexUsageWindow {
  used_percent: number;
  limit_window_seconds: number;
  reset_after_seconds: number;
  reset_at: number; // unix seconds
}

interface CodexUsageResponse {
  plan_type?: string;
  rate_limit?: {
    allowed: boolean;
    limit_reached: boolean;
    primary_window: CodexUsageWindow;
    secondary_window: CodexUsageWindow | null;
  };
  code_review_rate_limit?: {
    allowed: boolean;
    limit_reached: boolean;
    primary_window: CodexUsageWindow;
    secondary_window: CodexUsageWindow | null;
  };
  credits?: {
    has_credits: boolean;
    unlimited: boolean;
    balance: string;
    approx_local_messages?: [number, number];
    approx_cloud_messages?: [number, number];
  };
}

type Provider = "anthropic" | "openai-codex" | string;

type QuotaInfo = {
  statusKey: string;
  statusText: string;
  notify?: { message: string; type: "info" | "warning" | "error" };
};

export default function (pi: ExtensionAPI) {
  // Anthropic cache
  let cachedAnthropicUsage: UsageLimitData | null = null;
  let lastAnthropicFetched = 0;

  // Codex cache
  let cachedCodexUsage: CodexUsageResponse | null = null;
  let lastCodexFetched = 0;

  pi.on("model_select", async (event, ctx) => {
    const quota = await getQuotaForProvider(event.model.provider, ctx.ui.theme);

    ctx.ui.setStatus("model-quota", undefined);

    if (!quota) return;

    ctx.ui.setStatus(quota.statusKey, quota.statusText);
    if (quota.notify) {
      ctx.ui.notify(quota.notify.message, quota.notify.type);
    }
  });

  // Manual command
  pi.registerCommand("model-quota", {
    description:
      "Show model quota for the current provider (Anthropic + OpenAI Codex supported)",
    handler: async (_args, ctx) => {
      // Clear caches to get fresh data
      cachedAnthropicUsage = null;
      cachedCodexUsage = null;

      // pi extensions don't get direct access to the selected provider inside commands.
      // So we show both if available.
      const [anthropic, codex] = await Promise.all([
        getQuotaForProvider("anthropic", ctx.ui.theme),
        getQuotaForProvider("openai-codex", ctx.ui.theme),
      ]);

      const lines: string[] = [];
      if (anthropic)
        lines.push(`Anthropic: ${stripAnsiLike(anthropic.statusText)}`);
      if (codex) lines.push(`OpenAI/Codex: ${stripAnsiLike(codex.statusText)}`);

      if (lines.length === 0) {
        ctx.ui.notify(
          "No quota info available. Make sure you are logged in (OAuth) for Anthropic and/or ChatGPT (Codex).",
          "info",
        );
        return;
      }

      ctx.ui.notify(lines.join("\n"), "info");
    },
  });

  async function getQuotaForProvider(
    provider: Provider,
    theme: any | undefined,
  ): Promise<QuotaInfo | null> {
    if (provider === "anthropic") return getAnthropicQuota(theme);
    if (provider === "openai-codex") return getCodexQuota(theme);
    return null;
  }

  async function getAnthropicQuota(
    theme: any | undefined,
  ): Promise<QuotaInfo | null> {
    const usage = await fetchAnthropicUsage();
    if (!usage) return null;

    // NOTE: Anthropic returns utilization as 0-1, we display as percent.
    const sessionPercent = Math.round(usage.five_hour.utilization);
    const weeklyPercent = Math.round(usage.seven_day.utilization);

    const sessionReset = formatTimeUntilIso(usage.five_hour.resets_at);
    const weeklyReset = formatTimeUntilIso(usage.seven_day.resets_at);
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

    let notify: QuotaInfo["notify"];
    if (sessionPercent >= 100 || weeklyPercent >= 100) {
      // No notification if quota is exhausted
    } else if (sessionPercent > 95 || weeklyPercent > 95) {
      notify = { message: "Anthropic quota nearly exhausted!", type: "error" };
    } else if (sessionPercent > 85 || weeklyPercent > 85) {
      notify = { message: "Anthropic quota warning", type: "warning" };
    }

    return {
      statusKey: "model-quota",
      statusText: status,
      notify,
    };
  }

  async function getCodexQuota(
    theme: any | undefined,
  ): Promise<QuotaInfo | null> {
    const usage = await fetchCodexUsage();
    if (!usage?.rate_limit) return null;

    const primary = usage.rate_limit.primary_window;
    const secondary = usage.rate_limit.secondary_window;

    const primaryLeft = formatTimeUntilUnixSeconds(primary.reset_at);
    const secondaryLeft = secondary
      ? formatTimeUntilUnixSeconds(secondary.reset_at)
      : null;

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
      theme?.fg("dim", ` (${primaryLeft})`) || ` (${primaryLeft})`;

    const weeklyPart = secondary
      ? `${separator}${weeklyLabel}${colorPercent(secondary.used_percent)}${
          theme?.fg("dim", ` (${secondaryLeft})`) || ` (${secondaryLeft})`
        }`
      : "";

    const credits = usage.credits?.balance
      ? theme?.fg("dim", ` | credits: ${usage.credits.balance}`) ||
        ` | credits: ${usage.credits.balance}`
      : "";

    const status = `${sessionLabel}${colorPercent(primary.used_percent)}${sessionTime}${weeklyPart}${credits}`;

    let notify: QuotaInfo["notify"];
    if (
      primary.used_percent >= 100 ||
      (secondary && secondary.used_percent >= 100)
    ) {
      // No notification if exhausted
    } else if (
      primary.used_percent > 95 ||
      (secondary && secondary.used_percent > 95)
    ) {
      notify = {
        message: "OpenAI/Codex quota nearly exhausted!",
        type: "error",
      };
    } else if (
      primary.used_percent > 85 ||
      (secondary && secondary.used_percent > 85)
    ) {
      notify = { message: "OpenAI/Codex quota warning", type: "warning" };
    }

    return {
      statusKey: "model-quota",
      statusText: status,
      notify,
    };
  }

  function formatTimeUntilIso(isoString: string): string {
    const now = Date.now();
    const reset = new Date(isoString).getTime();
    return formatDiffMs(reset - now);
  }

  function formatTimeUntilUnixSeconds(unixSeconds: number): string {
    const now = Date.now();
    const reset = unixSeconds * 1000;
    return formatDiffMs(reset - now);
  }

  function formatDiffMs(diffMs: number): string {
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

  // Very small helper so /model-quota output doesn't contain theme escape sequences.
  function stripAnsiLike(text: string): string {
    // pi theme strings are plain text, but we defensively strip common ANSI just in case.
    return text.replace(/\x1b\[[0-9;]*m/g, "");
  }

  async function fetchAnthropicUsage(): Promise<UsageLimitData | null> {
    // Cache for 5 minutes
    const now = Date.now();
    if (cachedAnthropicUsage && now - lastAnthropicFetched < 5 * 60 * 1000) {
      return cachedAnthropicUsage;
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

      cachedAnthropicUsage = await response.json();
      lastAnthropicFetched = now;
      return cachedAnthropicUsage;
    } catch (error) {
      console.error("Failed to fetch OAuth usage:", error);
      return null;
    }
  }

  async function fetchCodexUsage(): Promise<CodexUsageResponse | null> {
    // Cache for 60 seconds
    const now = Date.now();
    if (cachedCodexUsage && now - lastCodexFetched < 60 * 1000) {
      return cachedCodexUsage;
    }

    try {
      const authPath = `${process.env.HOME}/.pi/agent/auth.json`;
      const authData = JSON.parse(readFileSync(authPath, "utf8"));
      const codexAuth = authData["openai-codex"];
      if (!codexAuth?.access) return null;

      const token = codexAuth.access as string;

      // ChatGPT web client sends a bunch of OAI-* headers, but this endpoint appears
      // to work with just Authorization.
      const response = await fetch(
        "https://chatgpt.com/backend-api/wham/usage",
        {
          method: "GET",
          headers: {
            Authorization: `Bearer ${token}`,
            Accept: "application/json",
          },
        },
      );

      if (!response.ok) {
        return null;
      }

      cachedCodexUsage = (await response.json()) as CodexUsageResponse;
      lastCodexFetched = now;
      return cachedCodexUsage;
    } catch {
      return null;
    }
  }

  // Kept around for future endpoints that may require chatgpt-account-id.
  function extractChatGPTAccountId(token: string): string {
    const parts = token.split(".");
    if (parts.length !== 3) throw new Error("Invalid JWT");

    const base64 = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const pad = "=".repeat((4 - (base64.length % 4)) % 4);
    const json = JSON.parse(
      Buffer.from(base64 + pad, "base64").toString("utf8"),
    );

    const claim = json?.["https://api.openai.com/auth"];
    const accountId = claim?.chatgpt_account_id;
    if (!accountId) throw new Error("No chatgpt_account_id in token");
    return accountId;
  }
}
