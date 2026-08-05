import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export function enableFastMode(payload: unknown): unknown {
  if (!payload || typeof payload !== "object" || Array.isArray(payload)) {
    return payload;
  }

  return { ...payload, service_tier: "priority" };
}

export default function (pi: ExtensionAPI) {
  pi.on("before_provider_request", (event, ctx) => {
    if (
      ctx.model?.provider === "openai-codex" &&
      ctx.model.id === "gpt-5.6-sol" &&
      ctx.thinkingLevel === "xhigh"
    ) {
      return enableFastMode(event.payload);
    }
  });
}
