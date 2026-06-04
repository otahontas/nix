import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

type Provider = string;

// Auth config (~/.pi/agent/auth.json)
interface AuthConfig {
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

const PI_AUTH_PATH = join(homedir(), ".pi", "agent", "auth.json");
const FETCH_TIMEOUT_MS = 10_000;
const MODEL_QUOTA_DEBUG = process.env.PI_MODEL_QUOTA_DEBUG === "1";

export default function (pi: ExtensionAPI) {
  // OpenAI Codex quota cache
  let cachedCodexUsage: CodexUsageResponse | null = null;
  let lastCodexFetched = 0;

  // auth.json cache
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
    if (provider === "openai-codex") {
      cachedCodexUsage = null;
      lastCodexFetched = 0;
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
    description: "Show OpenAI Codex model quota",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) return;

      // Clear caches to get fresh data.
      cachedCodexUsage = null;
      lastCodexFetched = 0;
      cachedAuthData = null;
      lastAuthFetched = 0;
      authFetchInFlight = null;

      const codex = await getQuotaForProvider("openai-codex", ctx.ui.theme);
      const statusText = stripAnsiLike(codex.statusText);
      const message = statusText.startsWith("OpenAI Codex: ")
        ? statusText
        : `OpenAI Codex: ${statusText}`;

      ctx.ui.notify(message, "info");
    },
  });

  async function getQuotaForProvider(
    provider: Provider,
    theme: ThemeLike | undefined,
  ): Promise<QuotaInfo> {
    if (provider === "openai-codex") return getCodexQuota(theme);
    return {
      statusText: themed(theme, "dim", "OpenAI Codex quota only"),
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
    // Cache for 60 seconds.
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
}
