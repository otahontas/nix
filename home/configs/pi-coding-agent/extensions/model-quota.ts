import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

// Anthropic OAuth usage API response format
interface LimitWindow {
  utilization: number; // Percent in range 0-100
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

// Gemini CLI quota endpoints
interface GeminiCliAuthCredential {
  type?: string;
  access?: string;
  refresh?: string;
  expires?: number;
}

interface GeminiCliLoadResponse {
  cloudaicompanionProject?: string;
}

interface GeminiCliQuotaBucket {
  remainingAmount?: string;
  remainingFraction?: number;
  resetTime?: string;
  tokenType?: string;
  modelId?: string;
}

interface GeminiCliQuotaResponse {
  buckets?: GeminiCliQuotaBucket[];
}

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

type Provider =
  | "anthropic"
  | "openai-codex"
  | "google-gemini-cli"
  | "google-antigravity"
  | "github-copilot"
  | string;

type QuotaInfo = {
  statusText: string;
  notify?: { message: string; type: "info" | "warning" | "error" };
};

type ThemeColor = "muted" | "error" | "warning" | "success" | "dim";

type ThemeLike = {
  fg: (color: ThemeColor, text: string) => string;
};

const GEMINI_CODE_ASSIST_BASE_URL =
  "https://cloudcode-pa.googleapis.com/v1internal";
const GEMINI_CODE_ASSIST_LOAD_URL = `${GEMINI_CODE_ASSIST_BASE_URL}:loadCodeAssist`;
const GEMINI_CODE_ASSIST_QUOTA_URL = `${GEMINI_CODE_ASSIST_BASE_URL}:retrieveUserQuota`;

const ANTIGRAVITY_BASE_URL =
  "https://daily-cloudcode-pa.sandbox.googleapis.com";
const ANTIGRAVITY_QUOTA_URL = `${ANTIGRAVITY_BASE_URL}/v1internal:retrieveUserQuota`;

const ANTIGRAVITY_HEADERS = {
  "User-Agent": "antigravity/1.15.8 darwin/arm64",
  "X-Goog-Api-Client": "google-cloud-sdk vscode_cloudshelleditor/0.1",
  "Client-Metadata": JSON.stringify({
    ideType: "IDE_UNSPECIFIED",
    platform: "PLATFORM_UNSPECIFIED",
    pluginType: "GEMINI",
  }),
};

const PI_AUTH_PATH = join(homedir(), ".pi", "agent", "auth.json");
const FETCH_TIMEOUT_MS = 10_000;
const MODEL_QUOTA_DEBUG = process.env.PI_MODEL_QUOTA_DEBUG === "1";

export default function (pi: ExtensionAPI) {
  // Anthropic cache
  let cachedAnthropicUsage: UsageLimitData | null = null;
  let lastAnthropicFetched = 0;

  // Codex cache
  let cachedCodexUsage: CodexUsageResponse | null = null;
  let lastCodexFetched = 0;

  // GitHub Copilot cache
  let cachedGitHubCopilotUser: GitHubCopilotUserResponse | null = null;
  let lastGitHubCopilotFetched = 0;

  // Google Antigravity cache
  let cachedAntigravityQuota: GeminiCliQuotaResponse | null = null;
  let lastAntigravityFetched = 0;

  // Gemini CLI cache
  let cachedGeminiQuota: GeminiCliQuotaResponse | null = null;
  let lastGeminiFetched = 0;
  let cachedGeminiProjectId: string | null = null;
  let lastGeminiProjectFetched = 0;

  // auth.json cache (shared by all providers)
  let cachedAuthData: any | null = null;
  let lastAuthFetched = 0;
  let authFetchInFlight: Promise<any | null> | null = null;

  function logDebug(...args: any[]) {
    if (MODEL_QUOTA_DEBUG) console.error(...args);
  }

  const autoRefreshKey = Symbol.for(
    "@otahontas/pi:model-quota:autoRefreshTimer",
  );
  const existingAutoRefreshTimer = (globalThis as any)[autoRefreshKey] as
    | ReturnType<typeof setInterval>
    | undefined;
  if (existingAutoRefreshTimer) clearInterval(existingAutoRefreshTimer);
  (globalThis as any)[autoRefreshKey] = undefined;

  let autoRefreshTimer: ReturnType<typeof setInterval> | null = null;

  let activeProvider: Provider | null = null;
  let activeModelId: string | undefined;

  let refreshSeq = 0;
  let lastSuccessfulRefreshAt = 0;
  let lastSuccessfulProvider: Provider | null = null;
  let lastSuccessfulModelId: string | null = null;

  function clearCachesForProvider(provider: Provider) {
    if (provider === "anthropic") {
      cachedAnthropicUsage = null;
      lastAnthropicFetched = 0;
      return;
    }

    if (provider === "openai-codex") {
      cachedCodexUsage = null;
      lastCodexFetched = 0;
      return;
    }

    if (provider === "github-copilot") {
      cachedGitHubCopilotUser = null;
      lastGitHubCopilotFetched = 0;
      return;
    }

    if (provider === "google-antigravity") {
      cachedAntigravityQuota = null;
      lastAntigravityFetched = 0;
      return;
    }

    if (provider === "google-gemini-cli" || provider === "gemini-cli") {
      cachedGeminiQuota = null;
      lastGeminiFetched = 0;
      return;
    }
  }

  function providerSupportsQuota(provider: Provider): boolean {
    return (
      provider === "anthropic" ||
      provider === "openai-codex" ||
      provider === "github-copilot" ||
      provider === "google-antigravity" ||
      provider === "google-gemini-cli" ||
      provider === "gemini-cli"
    );
  }

  async function refreshQuotaForActiveModel(
    ctx: any,
    options: { force?: boolean; notify?: boolean } = {},
  ) {
    if (!ctx?.hasUI) return;
    if (!activeProvider) return;

    const seq = ++refreshSeq;

    if (!providerSupportsQuota(activeProvider)) {
      ctx.ui.setStatus(
        "model-quota",
        themed(ctx.ui.theme, "dim", "model quota not implemented"),
      );
      return;
    }

    if (options.force) {
      clearCachesForProvider(activeProvider);
    }

    const quota = await getQuotaForProvider(
      activeProvider,
      ctx.ui.theme,
      activeModelId,
      ctx,
    );

    // Only apply the latest refresh.
    if (seq !== refreshSeq) return;

    if (!quota) {
      ctx.ui.setStatus("model-quota", undefined);
      return;
    }

    ctx.ui.setStatus("model-quota", quota.statusText);

    if (options.notify && quota.notify) {
      ctx.ui.notify(quota.notify.message, quota.notify.type);
    }

    lastSuccessfulRefreshAt = Date.now();
    lastSuccessfulProvider = activeProvider;
    lastSuccessfulModelId = activeModelId ?? null;
  }

  function startAutoRefresh(ctx: any) {
    if (autoRefreshTimer) return;

    autoRefreshTimer = setInterval(
      () => {
        void refreshQuotaForActiveModel(ctx, { force: true, notify: false });
      },
      5 * 60 * 1000,
    );

    (globalThis as any)[autoRefreshKey] = autoRefreshTimer;
  }

  pi.on("session_shutdown", async (_event, _ctx) => {
    if (autoRefreshTimer) {
      clearInterval(autoRefreshTimer);
      autoRefreshTimer = null;
    }
    (globalThis as any)[autoRefreshKey] = undefined;
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
      "Show model quota for the current provider (Anthropic + OpenAI Codex + GitHub Copilot + Gemini CLI + Google Antigravity supported)",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) return;

      // Clear caches to get fresh data
      cachedAnthropicUsage = null;
      cachedCodexUsage = null;
      cachedGitHubCopilotUser = null;
      lastGitHubCopilotFetched = 0;
      cachedAntigravityQuota = null;
      lastAntigravityFetched = 0;
      cachedGeminiQuota = null;
      cachedGeminiProjectId = null;
      cachedAuthData = null;
      lastAuthFetched = 0;
      authFetchInFlight = null;

      // pi extensions don't get direct access to the selected provider inside commands.
      // So we show all providers if available.
      const [anthropic, codex, copilot, antigravity, gemini] =
        await Promise.all([
          getQuotaForProvider("anthropic", ctx.ui.theme, undefined, ctx),
          getQuotaForProvider("openai-codex", ctx.ui.theme, undefined, ctx),
          getQuotaForProvider("github-copilot", ctx.ui.theme, undefined, ctx),
          getQuotaForProvider(
            "google-antigravity",
            ctx.ui.theme,
            undefined,
            ctx,
          ),
          getQuotaForProvider(
            "google-gemini-cli",
            ctx.ui.theme,
            undefined,
            ctx,
          ),
        ]);

      const lines: string[] = [];
      if (anthropic)
        lines.push(`Anthropic: ${stripAnsiLike(anthropic.statusText)}`);
      if (codex) lines.push(`OpenAI/Codex: ${stripAnsiLike(codex.statusText)}`);
      if (copilot)
        lines.push(`GitHub Copilot: ${stripAnsiLike(copilot.statusText)}`);
      if (antigravity)
        lines.push(
          `Google Antigravity: ${stripAnsiLike(antigravity.statusText)}`,
        );
      if (gemini) lines.push(`Gemini CLI: ${stripAnsiLike(gemini.statusText)}`);

      if (lines.length === 0) {
        ctx.ui.notify(
          "No quota info available. Make sure you are logged in (OAuth) for Anthropic, ChatGPT (Codex), GitHub Copilot, Gemini CLI, or Google Antigravity.",
          "info",
        );
        return;
      }

      ctx.ui.notify(lines.join("\n"), "info");
    },
  });

  async function getQuotaForProvider(
    provider: Provider,
    theme: ThemeLike | undefined,
    modelId: string | undefined,
    ctx: any,
  ): Promise<QuotaInfo | null> {
    if (provider === "anthropic") return getAnthropicQuota(theme);
    if (provider === "openai-codex") return getCodexQuota(theme);
    if (provider === "github-copilot") return getGitHubCopilotQuota(theme);
    if (provider === "google-antigravity") {
      return getAntigravityQuota(theme, modelId, ctx);
    }
    if (provider === "google-gemini-cli" || provider === "gemini-cli") {
      return getGeminiQuota(theme, modelId);
    }
    return null;
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

  function isZeroNumberString(text: string): boolean {
    const n = Number(text);
    return Number.isFinite(n) && n <= 0;
  }

  async function getAnthropicQuota(
    theme: ThemeLike | undefined,
  ): Promise<QuotaInfo | null> {
    const usage = await fetchAnthropicUsage();
    if (!usage) return null;

    // NOTE: Anthropic returns utilization as a percent in range 0-100.
    const sessionPercent = Math.round(usage.five_hour.utilization);
    const weeklyPercent = Math.round(usage.seven_day.utilization);

    const sessionReset = formatTimeUntilIso(usage.five_hour.resets_at);
    const weeklyReset = formatTimeUntilIso(usage.seven_day.resets_at);

    const sessionLabel = themed(theme, "muted", "session: ");
    const weeklyLabel = themed(theme, "muted", "weekly: ");
    const separator = themed(theme, "dim", " | ");
    const sessionTime = themed(theme, "dim", ` (${sessionReset})`);
    const weeklyTime = themed(theme, "dim", ` (${weeklyReset})`);

    const status = `${sessionLabel}${formatUsedPercent(theme, sessionPercent)}${sessionTime}${separator}${weeklyLabel}${formatUsedPercent(theme, weeklyPercent)}${weeklyTime}`;

    let notify: QuotaInfo["notify"];
    if (sessionPercent >= 100 || weeklyPercent >= 100) {
      // No notification if quota is exhausted
    } else if (sessionPercent > 95 || weeklyPercent > 95) {
      notify = { message: "Anthropic quota nearly exhausted!", type: "error" };
    } else if (sessionPercent > 85 || weeklyPercent > 85) {
      notify = { message: "Anthropic quota warning", type: "warning" };
    }

    return {
      statusText: status,
      notify,
    };
  }

  async function getCodexQuota(
    theme: ThemeLike | undefined,
  ): Promise<QuotaInfo | null> {
    const usage = await fetchCodexUsage();
    if (!usage?.rate_limit) return null;

    const primary = usage.rate_limit.primary_window;
    const secondary = usage.rate_limit.secondary_window;

    const primaryLeft = formatTimeUntilUnixSeconds(primary.reset_at);
    const secondaryLeft = secondary
      ? formatTimeUntilUnixSeconds(secondary.reset_at)
      : "";

    const sessionLabel = themed(theme, "muted", "session: ");
    const weeklyLabel = themed(theme, "muted", "weekly: ");
    const separator = themed(theme, "dim", " | ");

    const sessionTime = themed(theme, "dim", ` (${primaryLeft})`);

    const weeklyPart = secondary
      ? `${separator}${weeklyLabel}${formatUsedPercent(theme, secondary.used_percent)}${themed(theme, "dim", ` (${secondaryLeft})`)}`
      : "";

    const creditsBalance = usage.credits?.balance;
    const credits =
      creditsBalance && !isZeroNumberString(creditsBalance)
        ? themed(theme, "dim", ` | credits: ${creditsBalance}`)
        : "";

    const status = `${sessionLabel}${formatUsedPercent(theme, primary.used_percent)}${sessionTime}${weeklyPart}${credits}`;

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
      statusText: status,
      notify,
    };
  }

  async function getGitHubCopilotQuota(
    theme: ThemeLike | undefined,
  ): Promise<QuotaInfo | null> {
    const user = await fetchGitHubCopilotUser();
    const premium = user?.quota_snapshots?.premium_interactions;
    if (!user || !premium) return null;

    const resetText = user.quota_reset_date_utc
      ? formatTimeUntilIso(user.quota_reset_date_utc)
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

    if (usedPercent == null) return null;
    usedPercent = Math.max(0, Math.min(100, usedPercent));

    const status = `${monthlyLabel}${formatUsedPercent(theme, usedPercent)}${timePart}`;

    let notify: QuotaInfo["notify"];
    if (usedPercent >= 100) {
      // No notification if exhausted
    } else if (usedPercent > 95) {
      notify = {
        message: "GitHub Copilot quota nearly exhausted!",
        type: "error",
      };
    } else if (usedPercent > 85) {
      notify = { message: "GitHub Copilot quota warning", type: "warning" };
    }

    return { statusText: status, notify };
  }

  async function getAntigravityQuota(
    theme: ThemeLike | undefined,
    modelId: string | undefined,
    ctx: any,
  ): Promise<QuotaInfo | null> {
    const quota = await fetchAntigravityQuota(ctx);
    if (!quota?.buckets?.length) return null;

    const bucket = selectAntigravityQuotaBucket(quota.buckets, modelId);
    if (!bucket || bucket.remainingFraction == null) return null;

    const usedPercent = Math.max(
      0,
      Math.min(100, Math.round((1 - bucket.remainingFraction) * 100)),
    );
    const resetText = bucket.resetTime
      ? formatTimeUntilIso(bucket.resetTime)
      : null;

    const sessionLabel = themed(theme, "muted", "session: ");
    const timePart = resetText ? themed(theme, "dim", ` (${resetText})`) : "";

    const status = `${sessionLabel}${formatUsedPercent(theme, usedPercent)}${timePart}`;

    let notify: QuotaInfo["notify"];
    if (usedPercent >= 100) {
      // No notification if exhausted
    } else if (usedPercent > 95) {
      notify = {
        message: "Google Antigravity quota nearly exhausted!",
        type: "error",
      };
    } else if (usedPercent > 85) {
      notify = { message: "Google Antigravity quota warning", type: "warning" };
    }

    return {
      statusText: status,
      notify,
    };
  }

  async function getGeminiQuota(
    theme: ThemeLike | undefined,
    modelId?: string,
  ): Promise<QuotaInfo | null> {
    const quota = await fetchGeminiQuota();
    if (!quota?.buckets?.length) return null;

    const bucket = selectGeminiQuotaBucket(quota.buckets, modelId);
    if (!bucket || bucket.remainingFraction == null) return null;

    const usedPercent = Math.max(
      0,
      Math.min(100, Math.round((1 - bucket.remainingFraction) * 100)),
    );
    const resetText = bucket.resetTime
      ? formatTimeUntilIso(bucket.resetTime)
      : null;

    const sessionLabel = themed(theme, "muted", "session: ");
    const timePart = resetText ? themed(theme, "dim", ` (${resetText})`) : "";

    const status = `${sessionLabel}${formatUsedPercent(theme, usedPercent)}${timePart}`;

    let notify: QuotaInfo["notify"];
    if (usedPercent >= 100) {
      // No notification if exhausted
    } else if (usedPercent > 95) {
      notify = { message: "Gemini CLI quota nearly exhausted!", type: "error" };
    } else if (usedPercent > 85) {
      notify = { message: "Gemini CLI quota warning", type: "warning" };
    }

    return {
      statusText: status,
      notify,
    };
  }

  function selectAntigravityQuotaBucket(
    buckets: GeminiCliQuotaBucket[],
    modelId?: string,
  ): GeminiCliQuotaBucket | null {
    const usable = buckets.filter((bucket) => bucket.remainingFraction != null);
    if (usable.length === 0) return null;

    if (modelId) {
      const normalizedModelId = normalizeAntigravityModelId(modelId);
      const match = usable.find(
        (bucket) =>
          bucket.modelId &&
          normalizeAntigravityModelId(bucket.modelId) === normalizedModelId,
      );
      if (match) return match;
    }

    return usable.reduce((lowest, bucket) =>
      (bucket.remainingFraction ?? 1) < (lowest.remainingFraction ?? 1)
        ? bucket
        : lowest,
    );
  }

  function normalizeAntigravityModelId(modelId: string): string {
    const raw = modelId.includes("/")
      ? modelId.split("/").pop() || modelId
      : modelId;
    return raw
      .replace(/-(thinking|xhigh|high|medium|low|minimal|off)$/i, "")
      .replace(/-001$/i, "");
  }

  function selectGeminiQuotaBucket(
    buckets: GeminiCliQuotaBucket[],
    modelId?: string,
  ): GeminiCliQuotaBucket | null {
    const usable = buckets.filter((bucket) => bucket.remainingFraction != null);
    if (usable.length === 0) return null;

    if (modelId) {
      const normalizedModelId = normalizeGeminiModelId(modelId);
      const match = usable.find(
        (bucket) =>
          bucket.modelId &&
          normalizeGeminiModelId(bucket.modelId) === normalizedModelId,
      );
      if (match) return match;
    }

    return usable.reduce((lowest, bucket) =>
      (bucket.remainingFraction ?? 1) < (lowest.remainingFraction ?? 1)
        ? bucket
        : lowest,
    );
  }

  function normalizeGeminiModelId(modelId: string): string {
    return modelId.replace(/-001$/, "");
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

  async function readAuthData(): Promise<any | null> {
    const now = Date.now();
    if (cachedAuthData && now - lastAuthFetched < 1000) return cachedAuthData;
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

  async function fetchAnthropicUsage(): Promise<UsageLimitData | null> {
    // Cache for 5 minutes
    const now = Date.now();
    if (cachedAnthropicUsage && now - lastAnthropicFetched < 5 * 60 * 1000) {
      return cachedAnthropicUsage;
    }

    try {
      const authData = await readAuthData();
      const anthropicAuth = authData?.anthropic;
      if (!anthropicAuth?.access) return null;

      const response = await fetchWithTimeout(
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
        logDebug("OAuth usage API error:", response.status);
        return null;
      }

      cachedAnthropicUsage = await response.json();
      lastAnthropicFetched = now;
      return cachedAnthropicUsage;
    } catch (error) {
      logDebug("Failed to fetch OAuth usage:", error);
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
      const authData = await readAuthData();
      const codexAuth = authData?.["openai-codex"];
      if (!codexAuth?.access) return null;

      const token = codexAuth.access as string;

      // ChatGPT web client sends a bunch of OAI-* headers, but this endpoint appears
      // to work with just Authorization.
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
        return null;
      }

      cachedCodexUsage = (await response.json()) as CodexUsageResponse;
      lastCodexFetched = now;
      return cachedCodexUsage;
    } catch (error) {
      logDebug("Failed to fetch OpenAI/Codex usage:", error);
      return null;
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

  async function getAntigravityCredentials(ctx: any): Promise<{
    accessToken: string;
    projectId: string;
  } | null> {
    try {
      const raw =
        await ctx?.modelRegistry?.getApiKeyForProvider?.("google-antigravity");
      if (!raw) return null;

      const parsed = JSON.parse(raw) as { token?: string; projectId?: string };
      if (!parsed?.token || !parsed?.projectId) return null;

      return { accessToken: parsed.token, projectId: parsed.projectId };
    } catch {
      return null;
    }
  }

  async function fetchAntigravityQuota(
    ctx: any,
  ): Promise<GeminiCliQuotaResponse | null> {
    // Cache for 60 seconds
    const now = Date.now();
    if (cachedAntigravityQuota && now - lastAntigravityFetched < 60 * 1000) {
      return cachedAntigravityQuota;
    }

    try {
      const creds = await getAntigravityCredentials(ctx);
      if (!creds) return null;

      const response = await fetchWithTimeout(ANTIGRAVITY_QUOTA_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${creds.accessToken}`,
          "Content-Type": "application/json",
          Accept: "application/json",
          ...ANTIGRAVITY_HEADERS,
        },
        body: JSON.stringify({ project: creds.projectId }),
      });

      if (!response.ok) {
        logDebug("Google Antigravity quota API error:", response.status);
        return null;
      }

      cachedAntigravityQuota =
        (await response.json()) as unknown as GeminiCliQuotaResponse;
      lastAntigravityFetched = now;
      return cachedAntigravityQuota;
    } catch (error) {
      logDebug("Failed to fetch Google Antigravity quota:", error);
      return null;
    }
  }

  async function fetchGeminiQuota(): Promise<GeminiCliQuotaResponse | null> {
    // Cache for 60 seconds
    const now = Date.now();
    if (cachedGeminiQuota && now - lastGeminiFetched < 60 * 1000) {
      return cachedGeminiQuota;
    }

    try {
      const accessToken = await getGeminiAccessToken();
      if (!accessToken) return null;

      const projectId = await fetchGeminiProjectId(accessToken);
      if (!projectId) return null;

      const response = await fetchWithTimeout(GEMINI_CODE_ASSIST_QUOTA_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ project: projectId }),
      });

      if (!response.ok) {
        logDebug("Gemini CLI quota API error:", response.status);
        return null;
      }

      cachedGeminiQuota = (await response.json()) as GeminiCliQuotaResponse;
      lastGeminiFetched = now;
      return cachedGeminiQuota;
    } catch (error) {
      logDebug("Failed to fetch Gemini CLI quota:", error);
      return null;
    }
  }

  async function fetchGeminiProjectId(
    accessToken: string,
  ): Promise<string | null> {
    const now = Date.now();
    if (
      cachedGeminiProjectId &&
      now - lastGeminiProjectFetched < 5 * 60 * 1000
    ) {
      return cachedGeminiProjectId;
    }

    const envProjectId =
      process.env.GOOGLE_CLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT_ID;

    try {
      const metadata = {
        ideType: "IDE_UNSPECIFIED",
        platform: "PLATFORM_UNSPECIFIED",
        pluginType: "GEMINI",
        ...(envProjectId ? { duetProject: envProjectId } : {}),
      };

      const response = await fetchWithTimeout(GEMINI_CODE_ASSIST_LOAD_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          metadata,
          ...(envProjectId
            ? {
                cloudaicompanionProject: envProjectId,
              }
            : {}),
        }),
      });

      if (!response.ok) {
        if (envProjectId) {
          cachedGeminiProjectId = envProjectId;
          lastGeminiProjectFetched = now;
        }
        return envProjectId ?? null;
      }

      const payload = (await response.json()) as GeminiCliLoadResponse;
      cachedGeminiProjectId =
        payload.cloudaicompanionProject || envProjectId || null;
      lastGeminiProjectFetched = now;
      return cachedGeminiProjectId;
    } catch (error) {
      logDebug("Failed to load Gemini CLI project:", error);
      if (envProjectId) {
        cachedGeminiProjectId = envProjectId;
        lastGeminiProjectFetched = now;
      }
      return envProjectId ?? null;
    }
  }

  async function getGeminiAccessToken(): Promise<string | null> {
    const authData = await readAuthData();
    const geminiAuth =
      authData?.["google-gemini-cli"] ?? authData?.["gemini-cli"];
    if (!geminiAuth?.access) return null;
    return (geminiAuth as GeminiCliAuthCredential).access ?? null;
  }
}
