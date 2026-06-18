/**
 * Shows the starship prompt above Pi's built-in footer.
 *
 * This preserves Pi's default footer stats while hiding the built-in location
 * line that duplicates the starship prompt.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import {
  type Component,
  truncateToWidth,
  type TUI,
  visibleWidth,
} from "@earendil-works/pi-tui";
import { execFile as execFileCb } from "node:child_process";
import { promisify } from "node:util";

const execFile = promisify(execFileCb);
const FOOTER_COMPONENT_NAME = "FooterComponent";
const WIDGET_KEY = "starship";

type FooterComponentLike = Component;

function findFooterComponent(tui: TUI): FooterComponentLike | undefined {
  return tui.children.find(
    (child): child is FooterComponentLike =>
      typeof child.render === "function" &&
      (child as { constructor?: { name?: string } }).constructor?.name ===
        FOOTER_COMPONENT_NAME,
  );
}

function patchFooterLocationLine(tui: TUI): (() => void) | undefined {
  const footer = findFooterComponent(tui);
  if (!footer) return undefined;

  const originalRender = footer.render.bind(footer);
  footer.render = (width: number) => originalRender(width).slice(1);

  return () => {
    footer.render = originalRender;
  };
}

async function fetchStarship(cwd: string): Promise<string> {
  try {
    const { stdout: raw } = await execFile(
      "starship",
      ["prompt", "--status=0", "--cmd-duration=0", "--jobs=0"],
      {
        cwd,
        timeout: 500,
        env: { ...process.env, TERM_PROGRAM: "ghostty" },
      },
    );
    const cleaned = raw.replace(/\x1b\[[0-9]*[JKHG]/g, "");
    const line = cleaned.split("\n").find((l) => visibleWidth(l) > 2) ?? "";
    return line.replace(/^\s+/, "").replace(/\s+$/, "");
  } catch {
    return "";
  }
}

export default function (pi: ExtensionAPI) {
  let cachedStarship = "";
  let requestRender = () => {};
  let sessionGeneration = 0;
  let refreshInFlight = false;
  let restoreFooterRender: (() => void) | undefined;

  function installFooterPatch(tui: TUI) {
    if (restoreFooterRender) return;
    const restore = patchFooterLocationLine(tui);
    if (!restore) return;

    restoreFooterRender = () => {
      restore();
      restoreFooterRender = undefined;
    };
  }

  async function refreshStarship(cwd: string, generation: number) {
    if (refreshInFlight) return;

    refreshInFlight = true;
    try {
      const line = await fetchStarship(cwd);
      if (generation !== sessionGeneration) return;

      cachedStarship = line;
      requestRender();
    } finally {
      refreshInFlight = false;
    }
  }

  pi.on("session_start", (_event, ctx) => {
    if (!ctx.hasUI) return;

    const generation = ++sessionGeneration;
    cachedStarship = "";

    ctx.ui.setWidget(
      WIDGET_KEY,
      (tui) => {
        installFooterPatch(tui);
        requestRender = () => tui.requestRender();
        void refreshStarship(ctx.cwd, generation);

        return {
          invalidate() {},
          render(width: number): string[] {
            if (!cachedStarship) return [];
            return [truncateToWidth(cachedStarship, width)];
          },
        };
      },
      { placement: "belowEditor" },
    );
  });

  pi.on("agent_end", async (_event, ctx) => {
    if (!ctx.hasUI) return;

    await refreshStarship(ctx.cwd, sessionGeneration);
  });

  pi.on("session_shutdown", async (_event, ctx) => {
    sessionGeneration++;
    cachedStarship = "";
    requestRender = () => {};
    restoreFooterRender?.();

    if (ctx.hasUI) {
      ctx.ui.setWidget(WIDGET_KEY, undefined);
    }
  });
}
