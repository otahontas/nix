import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

// GitHub Copilot quota endpoint
interface GitHubCopilotQuotaSnapshot {
  entitlement?: number;
  percent_remaining?: number;
  remaining?: number;
  unlimited?: boolean;
  timestamp_utc?: string;
}

interface GitHubCopilotUserResponse {
  quota_reset_date_utc?: string;
  quota_snapshots?: {
    premium_interactions?: GitHubCopilotQuotaSnapshot;
    chat?: GitHubCopilotQuotaSnapshot;
    completions?: GitHubCopilotQuotaSnapshot;
  };
}
type Provider = "github-copilot" | "opencode-go" | "openai-codex" | string;

// Auth config (~/.pi/agent/auth.json)
interface AuthConfig {
  "github-copilot"?: {
    refresh?: string;
    enterpriseUrl?: string;
  };
  "opencode-go"?: {
    type?: string;
    key?: string;
  };
  "openai-codex"?: {
    access?: string;
  };
}

type QuotaInfo = {
  statusText: string;
  notify?: { message: string; type: "info" | "warning" | "error" };
};

type ThemeColor = "muted" | "error" | "warning" | "success" | "dim";

type ThemeLike = {
  fg: (color: ThemeColor, text: string) => string;
};

const PI_AUTH_PATH = join(homedir(), ".pi", "agent", "auth.json");

const FETCH_TIMEOUT_MS = 10_000;
const DASHBOARD_SCRAPE_TIMEOUT_MS = 10_000;
const USER_AGENT =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Gecko/20100101 Firefox/148.0";
const MODEL_QUOTA_DEBUG = process.env.PI_MODEL_QUOTA_DEBUG === "1";

export default function (pi: ExtensionAPI) {
  // GitHub Copilot cache
  let cachedGitHubCopilotUser: GitHubCopilotUserResponse | null = null;
  let lastGitHubCopilotFetched = 0;

  // OpenCode Go quota cache
  let cachedOpenCodeGoQuota: OpenCodeGoUsage | null = null;
  let lastOpenCodeGoFetched = 0;
  let lastOpenCodeGoFailureReason:
    | "api-404"
    | "api-error"
    | "scraper-failed"
    | "no-credentials"
    | null = null;

  // OpenAI Codex quota cache
  let cachedCodexUsage: CodexUsageResponse | null = null;
  let lastCodexFetched = 0;

  // auth.json cache (shared by all providers)
  let cachedAuthData: AuthConfig | null = null;
  let lastAuthFetched = 0;
  let authFetchInFlight: Promise<AuthConfig | null> | null = null;

  function logDebug(...args: any[]) {
    if (MODEL_QUOTA_DEBUG) console.error(...args);
  }

  let autoRefreshTimer: ReturnType<typeof setInterval> | null = null;

  let activeProvider: Provider | null = null;
  let activeModelId: string | undefined;

  let refreshSeq = 0;
  let lastSuccessfulRefreshAt = 0;
  let lastSuccessfulProvider: Provider | null = null;
  let lastSuccessfulModelId: string | null = null;

  function clearCachesForProvider(provider: Provider) {
    if (provider === "github-copilot") {
      cachedGitHubCopilotUser = null;
      lastGitHubCopilotFetched = 0;
      return;
    }

    if (provider === "opencode-go") {
      cachedOpenCodeGoQuota = null;
      lastOpenCodeGoFetched = 0;
      lastOpenCodeGoFailureReason = null;
      return;
    }

    if (provider === "openai-codex") {
      cachedCodexUsage = null;
      lastCodexFetched = 0;
      return;
    }
  }

  async function refreshQuotaForActiveModel(
    ctx: ExtensionContext,
    options: { force?: boolean; notify?: boolean } = {},
  ) {
    if (!ctx?.hasUI) return;
    if (!activeProvider) return;

    const seq = ++refreshSeq;

    if (options.force) {
      clearCachesForProvider(activeProvider);
    }

    const quota = await getQuotaForProvider(activeProvider, ctx.ui.theme);

    // Only apply the latest refresh.
    if (seq !== refreshSeq) return;

    ctx.ui.setStatus("model-quota", quota.statusText);

    if (options.notify && quota.notify) {
      ctx.ui.notify(quota.notify.message, quota.notify.type);
    }

    lastSuccessfulRefreshAt = Date.now();
    lastSuccessfulProvider = activeProvider;
    lastSuccessfulModelId = activeModelId ?? null;
  }

  function startAutoRefresh(ctx: ExtensionContext) {
    if (autoRefreshTimer) return;

    autoRefreshTimer = setInterval(
      () => {
        void refreshQuotaForActiveModel(ctx, { force: true, notify: false });
      },
      5 * 60 * 1000,
    );
  }

  pi.on("session_shutdown", async (_event, _ctx) => {
    if (autoRefreshTimer) {
      clearInterval(autoRefreshTimer);
      autoRefreshTimer = null;
    }
  });

  pi.on("session_start", async (_event, ctx) => {
    if (!ctx.hasUI) return;

    // Refresh right away on startup.
    if (ctx.model?.provider) {
      activeProvider = ctx.model.provider;
      activeModelId = ctx.model.id;
      await refreshQuotaForActiveModel(ctx, { force: true, notify: false });
    }

    startAutoRefresh(ctx);
  });

  pi.on("model_select", async (event, ctx) => {
    if (!ctx.hasUI) return;

    activeProvider = event.model.provider;
    activeModelId = event.model.id;

    const alreadyRefreshedOnStartup =
      event.source === "restore" &&
      lastSuccessfulProvider === activeProvider &&
      lastSuccessfulModelId === (activeModelId ?? null) &&
      Date.now() - lastSuccessfulRefreshAt < 2000;

    await refreshQuotaForActiveModel(ctx, {
      force: !alreadyRefreshedOnStartup,
      notify: true,
    });
  });

  // Manual command
  pi.registerCommand("model-quota", {
    description:
      "Show model quota for the current provider (GitHub Copilot, OpenAI Codex, OpenCode Go supported)",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) return;

      // Clear caches to get fresh data
      cachedGitHubCopilotUser = null;
      lastGitHubCopilotFetched = 0;
      cachedCodexUsage = null;
      lastCodexFetched = 0;
      cachedAuthData = null;
      lastAuthFetched = 0;
      authFetchInFlight = null;

      // pi extensions don't get direct access to the selected provider inside commands.
      // So we show all providers if available.
      const [copilot, codex, opencodeGo] = await Promise.all([
        getQuotaForProvider("github-copilot", ctx.ui.theme),
        getQuotaForProvider("openai-codex", ctx.ui.theme),
        getQuotaForProvider("opencode-go", ctx.ui.theme),
      ]);

      const lines: string[] = [
        `GitHub Copilot: ${stripAnsiLike(copilot.statusText)}`,
        `OpenAI Codex: ${stripAnsiLike(codex.statusText)}`,
        `OpenCode Go: ${stripAnsiLike(opencodeGo.statusText)}`,
      ];

      ctx.ui.notify(lines.join("\n"), "info");
    },
  });

  async function getQuotaForProvider(
    provider: Provider,
    theme: ThemeLike | undefined,
  ): QuotaInfo {
    if (provider === "github-copilot") return getGitHubCopilotQuota(theme);
    if (provider === "openai-codex") return getCodexQuota(theme);
    if (provider === "opencode-go") return getOpenCodeGoQuota(theme);
    return {
      statusText: themed(theme, "error", `Unknown provider`),
    };
  }

  function getQuotaNotification(
    percent: number,
    providerName: string,
  ): QuotaInfo["notify"] {
    if (percent >= 100) return undefined;
    if (percent > 95)
      return {
        message: `${providerName} quota nearly exhausted!`,
        type: "error",
      };
    if (percent > 85)
      return { message: `${providerName} quota warning`, type: "warning" };
    return undefined;
  }

  function formatTimeUntil(timestamp: number | string): string {
    const reset =
      typeof timestamp === "string"
        ? new Date(timestamp).getTime()
        : timestamp < 1e12
          ? timestamp * 1000 // unix seconds
          : timestamp; // unix ms
    const diffMs = reset - Date.now();
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

  function themed(
    theme: ThemeLike | undefined,
    color: ThemeColor,
    text: string,
  ): string {
    return theme ? theme.fg(color, text) : text;
  }

  function formatUsedPercent(
    theme: ThemeLike | undefined,
    pct: number,
  ): string {
    const text = `${pct}%`;
    if (!theme) return text;
    if (pct >= 100) return theme.fg("error", text);
    if (pct > 95) return theme.fg("error", text);
    if (pct > 85) return theme.fg("warning", text);
    return theme.fg("success", text);
  }

  async function getGitHubCopilotQuota(
    theme: ThemeLike | undefined,
  ): Promise<QuotaInfo> {
    const user = await fetchGitHubCopilotUser();
    if (!user) {
      return {
        statusText: themed(theme, "error", "GitHub Copilot: unavailable"),
      };
    }

    const premium = user?.quota_snapshots?.premium_interactions;
    if (!premium) {
      return {
        statusText: themed(theme, "error", "GitHub Copilot: no premium data"),
      };
    }

    const resetText = user.quota_reset_date_utc
      ? formatTimeUntil(user.quota_reset_date_utc)
      : null;

    const monthlyLabel = themed(theme, "muted", "monthly: ");
    const timePart = resetText ? themed(theme, "dim", ` (${resetText})`) : "";

    if (premium.unlimited) {
      return {
        statusText: `${monthlyLabel}${themed(theme, "success", "unlimited")}${timePart}`,
      };
    }

    let usedPercent: number | null = null;
    if (typeof premium.percent_remaining === "number") {
      usedPercent = Math.round(100 - premium.percent_remaining);
    } else if (
      typeof premium.entitlement === "number" &&
      premium.entitlement > 0 &&
      typeof premium.remaining === "number"
    ) {
      usedPercent = Math.round(
        ((premium.entitlement - premium.remaining) / premium.entitlement) * 100,
      );
    }

    if (usedPercent == null) {
      return {
        statusText: themed(
          theme,
          "error",
          "GitHub Copilot: cannot parse usage",
        ),
      };
    }
    usedPercent = Math.max(0, Math.min(100, usedPercent));

    const status = `${monthlyLabel}${formatUsedPercent(theme, usedPercent)}${timePart}`;

    return {
      statusText: status,
      notify: getQuotaNotification(usedPercent, "GitHub Copilot"),
    };
  }

  // Very small helper so /model-quota output doesn't contain theme escape sequences.
  function stripAnsiLike(text: string): string {
    // pi theme strings are plain text, but we defensively strip common ANSI just in case.
    return text.replace(/\x1b\[[0-9;]*m/g, "");
  }

  async function readAuthData(): Promise<AuthConfig | null> {
    const now = Date.now();
    if (cachedAuthData && now - lastAuthFetched < 60_000) return cachedAuthData;
    if (authFetchInFlight) return authFetchInFlight;

    const promise = (async () => {
      try {
        const raw = await readFile(PI_AUTH_PATH, "utf8");
        const data = JSON.parse(raw);
        cachedAuthData = data;
        lastAuthFetched = Date.now();
        return data;
      } catch {
        cachedAuthData = null;
        lastAuthFetched = 0;
        return null;
      } finally {
        authFetchInFlight = null;
      }
    })();

    authFetchInFlight = promise;
    return promise;
  }

  async function fetchWithTimeout(
    url: string,
    options: RequestInit,
    timeoutMs: number = FETCH_TIMEOUT_MS,
  ): Promise<Response> {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

    try {
      return await fetch(url, { ...options, signal: controller.signal });
    } finally {
      clearTimeout(timeoutId);
    }
  }

  function normalizeGitHubCopilotEnterpriseDomain(
    value: unknown,
  ): string | null {
    if (typeof value !== "string") return null;
    const trimmed = value.trim();
    if (!trimmed) return null;

    try {
      const url = trimmed.includes("://")
        ? new URL(trimmed)
        : new URL(`https://${trimmed}`);
      return url.hostname;
    } catch {
      return null;
    }
  }

  function getGitHubApiBaseUrl(domain: string): string {
    if (domain === "github.com") return "https://api.github.com";
    return `https://api.${domain}`;
  }

  async function fetchGitHubCopilotUser(): Promise<GitHubCopilotUserResponse | null> {
    // Cache for 60 seconds
    const now = Date.now();
    if (cachedGitHubCopilotUser && now - lastGitHubCopilotFetched < 60 * 1000) {
      return cachedGitHubCopilotUser;
    }

    try {
      const authData = await readAuthData();
      const copilotAuth = authData?.["github-copilot"];
      const refreshToken = copilotAuth?.refresh as string | undefined;
      if (!refreshToken) return null;

      const enterpriseDomain = normalizeGitHubCopilotEnterpriseDomain(
        copilotAuth?.enterpriseUrl,
      );
      const domain = enterpriseDomain || "github.com";
      const apiBaseUrl = getGitHubApiBaseUrl(domain);

      const response = await fetchWithTimeout(
        `${apiBaseUrl}/copilot_internal/user`,
        {
          method: "GET",
          headers: {
            Authorization: `Bearer ${refreshToken}`,
            Accept: "application/json",
            "User-Agent": "GitHubCopilotChat/0.35.0",
          },
        },
      );

      if (!response.ok) {
        logDebug("GitHub Copilot quota API error:", response.status);
        return null;
      }

      cachedGitHubCopilotUser =
        (await response.json()) as unknown as GitHubCopilotUserResponse;
      lastGitHubCopilotFetched = now;
      return cachedGitHubCopilotUser;
    } catch (error) {
      logDebug("Failed to fetch GitHub Copilot quota:", error);
      return null;
    }
  }

  // OpenAI Codex (ChatGPT subscription) usage endpoint
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

  async function getCodexQuota(
    theme: ThemeLike | undefined,
  ): Promise<QuotaInfo> {
    const usage = await fetchCodexUsage();
    if (!usage?.rate_limit) {
      return {
        statusText: themed(
          theme,
          "error",
          "OpenAI Codex: unavailable (check /login)",
        ),
      };
    }

    const primary = usage.rate_limit.primary_window;
    const secondary = usage.rate_limit.secondary_window;

    const sessionLabel = themed(theme, "muted", "session: ");
    const sessionTime = themed(
      theme,
      "dim",
      ` (${formatTimeUntil(primary.reset_at)})`,
    );

    const separator = themed(theme, "dim", " | ");

    let status = `${sessionLabel}${formatUsedPercent(theme, primary.used_percent)}${sessionTime}`;

    if (secondary) {
      const weeklyLabel = themed(theme, "muted", "weekly: ");
      const weeklyTime = themed(
        theme,
        "dim",
        ` (${formatTimeUntil(secondary.reset_at)})`,
      );
      status += `${separator}${weeklyLabel}${formatUsedPercent(theme, secondary.used_percent)}${weeklyTime}`;
    }

    if (usage.credits?.balance) {
      status += `${separator}${themed(theme, "dim", `credits: ${usage.credits.balance}`)}`;
    }

    const maxPercent = secondary
      ? Math.max(primary.used_percent, secondary.used_percent)
      : primary.used_percent;

    return {
      statusText: status,
      notify: getQuotaNotification(maxPercent, "OpenAI Codex"),
    };
  }

  async function fetchCodexUsage(): Promise<CodexUsageResponse | null> {
    // Cache for 60 seconds
    const now = Date.now();
    if (cachedCodexUsage && now - lastCodexFetched < 60 * 1000) {
      return cachedCodexUsage;
    }

    try {
      const authData = await readAuthData();
      const codexAuth = authData?.["openai-codex"];
      if (!codexAuth?.access) return null;

      const token = codexAuth.access as string;

      const response = await fetchWithTimeout(
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
        logDebug("OpenAI Codex quota API error:", response.status);
        return null;
      }

      cachedCodexUsage = (await response.json()) as CodexUsageResponse;
      lastCodexFetched = now;
      return cachedCodexUsage;
    } catch (error) {
      logDebug("Failed to fetch OpenAI Codex quota:", error);
      return null;
    }
  }

  // OpenCode Go usage endpoint response (zen/go/v1/usage)
  interface OpenCodeGoUsageWindow {
    status: "ok" | "rate-limited";
    resetInSec: number;
    usagePercent: number;
  }

  interface OpenCodeGoUsage {
    useBalance?: boolean;
    rollingUsage: OpenCodeGoUsageWindow;
    weeklyUsage: OpenCodeGoUsageWindow;
    monthlyUsage: OpenCodeGoUsageWindow;
  }

  const OPENCODE_GO_USAGE_URL = "https://opencode.ai/zen/go/v1/usage";

  async function getOpenCodeGoQuota(
    theme: ThemeLike | undefined,
  ): Promise<QuotaInfo> {
    const usage = await fetchOpenCodeGoUsage();
    if (!usage) {
      switch (lastOpenCodeGoFailureReason) {
        case "api-404":
          return {
            statusText: themed(theme, "dim", "OpenCode Go: quota API pending"),
          };
        case "scraper-failed":
          return {
            statusText: themed(theme, "error", "OpenCode Go: check auth"),
          };
        case "no-credentials":
          return {
            statusText: themed(theme, "error", "OpenCode Go: no auth"),
          };
        default:
          return {
            statusText: themed(theme, "error", "OpenCode Go: unavailable"),
          };
      }
    }

    const { rollingUsage, weeklyUsage, monthlyUsage } = usage;

    const rollingLabel = themed(theme, "muted", "5h: ");
    const rollingTime = themed(
      theme,
      "dim",
      ` (${formatTimeUntilSeconds(rollingUsage.resetInSec)})`,
    );
    const rollingPart = `${rollingLabel}${formatUsedPercent(theme, rollingUsage.usagePercent)}${rollingTime}`;

    const separator = themed(theme, "dim", " | ");

    const weeklyLabel = themed(theme, "muted", "wk: ");
    const weeklyTime = themed(
      theme,
      "dim",
      ` (${formatTimeUntilSeconds(weeklyUsage.resetInSec)})`,
    );
    const weeklyPart = `${weeklyLabel}${formatUsedPercent(theme, weeklyUsage.usagePercent)}${weeklyTime}`;

    const monthlyLabel = themed(theme, "muted", "mo: ");
    const monthlyTime = themed(
      theme,
      "dim",
      ` (${formatTimeUntilSeconds(monthlyUsage.resetInSec)})`,
    );
    const monthlyPart = `${monthlyLabel}${formatUsedPercent(theme, monthlyUsage.usagePercent)}${monthlyTime}`;

    const status = `${rollingPart}${separator}${weeklyPart}${separator}${monthlyPart}`;

    const maxPercent = Math.max(
      rollingUsage.usagePercent,
      weeklyUsage.usagePercent,
      monthlyUsage.usagePercent,
    );

    return {
      statusText: status,
      notify: getQuotaNotification(maxPercent, "OpenCode Go"),
    };
  }

  function formatTimeUntilSeconds(seconds: number): string {
    if (seconds <= 0) return "now";

    const diffMins = Math.floor(seconds / 60);
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

  // Dashboard scraper for OpenCode Go (fallback when /zen/go/v1/usage endpoint is unavailable)
  interface ScrapedWindow {
    usagePercent: number;
    resetInSec: number;
  }

  function parseUsageWindow(html: string, name: string): ScrapedWindow | null {
    // Match SolidJS SSR hydration patterns like:
    // rollingUsage:$R[0]={usagePercent:65,resetInSec:2520}
    // Fields may appear in either order.
    const NUM = "(-?\\d+(?:\\.\\d+)?)";
    const rePctFirst = new RegExp(
      `${name}:\\$R\\[\\d+\\]=\\{[^}]*usagePercent:${NUM}[^}]*resetInSec:${NUM}[^}]*\\}`,
    );
    const reResetFirst = new RegExp(
      `${name}:\\$R\\[\\d+\\]=\\{[^}]*resetInSec:${NUM}[^}]*usagePercent:${NUM}[^}]*\\}`,
    );

    let m = html.match(rePctFirst);
    if (m) {
      const usagePercent = Number(m[1]);
      const resetInSec = Number(m[2]);
      if (Number.isFinite(usagePercent) && Number.isFinite(resetInSec)) {
        return { usagePercent, resetInSec };
      }
    }

    m = html.match(reResetFirst);
    if (m) {
      const resetInSec = Number(m[1]);
      const usagePercent = Number(m[2]);
      if (Number.isFinite(usagePercent) && Number.isFinite(resetInSec)) {
        return { usagePercent, resetInSec };
      }
    }

    return null;
  }

  async function scrapeOpenCodeGoDashboard(): Promise<OpenCodeGoUsage | null> {
    const workspaceId = process.env.OPENCODE_GO_WORKSPACE_ID;
    const authCookie = process.env.OPENCODE_GO_AUTH_COOKIE;
    if (!workspaceId || !authCookie) return null;

    try {
      const url = `https://opencode.ai/workspace/${encodeURIComponent(workspaceId)}/go`;

      const response = await fetchWithTimeout(
        url,
        {
          method: "GET",
          headers: {
            "User-Agent": USER_AGENT,
            Accept: "text/html",
            Cookie: `auth=${authCookie}`,
          },
        },
        DASHBOARD_SCRAPE_TIMEOUT_MS,
      );

      if (!response.ok) {
        logDebug("OpenCode Go dashboard scrape error:", response.status);
        return null;
      }

      const html = await response.text();

      const rolling = parseUsageWindow(html, "rollingUsage");
      const weekly = parseUsageWindow(html, "weeklyUsage");
      const monthly = parseUsageWindow(html, "monthlyUsage");

      if (!rolling && !weekly && !monthly) {
        logDebug("OpenCode Go dashboard: could not parse any usage windows");
        return null;
      }

      return {
        rollingUsage: rolling ?? {
          status: "ok",
          resetInSec: 0,
          usagePercent: 0,
        },
        weeklyUsage: weekly ?? { status: "ok", resetInSec: 0, usagePercent: 0 },
        monthlyUsage: monthly ?? {
          status: "ok",
          resetInSec: 0,
          usagePercent: 0,
        },
      };
    } catch (error) {
      logDebug("Failed to scrape OpenCode Go usage:", error);
      return null;
    }
  }

  async function fetchOpenCodeGoUsage(): Promise<OpenCodeGoUsage | null> {
    // Cache for 60 seconds
    const now = Date.now();
    if (cachedOpenCodeGoQuota && now - lastOpenCodeGoFetched < 60 * 1000) {
      return cachedOpenCodeGoQuota;
    }

    // Try the API endpoint first (PR #16513 — /zen/go/v1/usage)
    try {
      const authData = await readAuthData();
      const opencodeGoAuth = authData?.["opencode-go"];

      let apiKey = opencodeGoAuth?.key;
      if (!apiKey) apiKey = process.env.OPENCODE_API_KEY || null;

      if (apiKey) {
        const response = await fetchWithTimeout(OPENCODE_GO_USAGE_URL, {
          method: "GET",
          headers: {
            Authorization: `Bearer ${apiKey}`,
            Accept: "application/json",
          },
        });

        if (response.ok) {
          cachedOpenCodeGoQuota = (await response.json()) as OpenCodeGoUsage;
          lastOpenCodeGoFetched = now;
          lastOpenCodeGoFailureReason = null;
          return cachedOpenCodeGoQuota;
        }

        logDebug("OpenCode Go usage API error:", response.status);
        // Only fall through to scraper on 404 (endpoint not available)
        if (response.status !== 404) {
          lastOpenCodeGoFailureReason = "api-error";
          return null;
        }
      } else {
        lastOpenCodeGoFailureReason = "no-credentials";
      }
    } catch (error) {
      logDebug("Failed to fetch OpenCode Go usage via API:", error);
      // Fall through to scraper
    }

    // Fallback: scrape the OpenCode Go dashboard
    const scraped = await scrapeOpenCodeGoDashboard();
    if (scraped) {
      cachedOpenCodeGoQuota = scraped;
      lastOpenCodeGoFetched = now;
      lastOpenCodeGoFailureReason = null;
      return scraped;
    }

    // If we got here with no reason set yet, check if scraper was attempted
    if (!lastOpenCodeGoFailureReason) {
      const hasScraperCreds =
        process.env.OPENCODE_GO_WORKSPACE_ID &&
        process.env.OPENCODE_GO_AUTH_COOKIE;
      if (hasScraperCreds) {
        lastOpenCodeGoFailureReason = "scraper-failed";
      } else {
        // API failed with 404 (endpoint doesn't exist) and no scraper creds
        lastOpenCodeGoFailureReason = "api-404";
      }
    }

    return null;
  }
}
