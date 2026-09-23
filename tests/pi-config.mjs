import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { registerHooks } from "node:module";

const piModule = import.meta
  .resolve("../.devenv/pi-node-modules/@earendil-works/pi-coding-agent/dist/index.js");
registerHooks({
  resolve(specifier, context, nextResolve) {
    return nextResolve(
      specifier,
      specifier === "typebox" || specifier.startsWith("@earendil-works/")
        ? { ...context, parentURL: piModule }
        : context,
    );
  },
});

const { ModelRuntime, SettingsManager } = await import(piModule);
const {
  InMemoryCredentialStore,
  InMemoryModelsStore,
  getSupportedThinkingLevels,
  clampThinkingLevel,
} = await import("@earendil-works/pi-ai");
const { default: stopHook } =
  await import("../home/configs/pi-coding-agent/extensions/stop-hook.ts");
const { default: lat } = await import("../.pi/extensions/lat.ts");
const settings = JSON.parse(
  readFileSync(
    new URL("../home/configs/pi-coding-agent/settings.json", import.meta.url),
  ),
);
const settingsManager = SettingsManager.inMemory(settings);
const runtime = await ModelRuntime.create({
  modelsPath: new URL(
    "../home/configs/pi-coding-agent/models.json",
    import.meta.url,
  ).pathname,
  credentials: new InMemoryCredentialStore(),
  modelsStore: new InMemoryModelsStore(),
  refreshOnCreate: false,
  allowModelNetwork: false,
});
assert.equal(settings.defaultModel, "gpt-6-sol");
assert.equal(settings.defaultThinkingLevel, "high");
assert.equal(settings.subagents.defaultModel, "openai-codex/gpt-6-sol");
assert.deepEqual(settings.enabledModels, [
  "openai-codex/gpt-6-sol:high",
  "openai-codex/gpt-6-astra:max",
]);
for (const [id, effort] of [
  ["gpt-6-sol", "high"],
  ["gpt-6-astra", "max"],
]) {
  const model = runtime.getModel("openai-codex", id);
  assert.equal(model.contextWindow, 872000);
  assert.deepEqual(getSupportedThinkingLevels(model), ["high", "xhigh", "max"]);
  assert.equal(clampThinkingLevel(model, "low"), "high");
  assert.equal(
    settingsManager.getModelThinkingLevel("openai-codex", id),
    effort,
  );
}

function handlersFor(extension, exec) {
  const handlers = new Map();
  extension({
    on: (name, handler) => handlers.set(name, handler),
    registerTool() {},
    registerMessageRenderer() {},
    exec,
  });
  assert.ok(!handlers.has("agent_end"));
  assert.ok(handlers.has("agent_before_settle"));
  return handlers;
}

const draft = { type: "custom", customType: "other-extension", data: {} };
const boundary = {
  entries: [draft],
  continue: false,
  outcome: "completed",
  context: {
    pendingMessages: [],
    contextMessages: [
      { role: "user", content: "Prior task" },
      { role: "assistant", content: [{ type: "toolCall", name: "bash" }] },
      { role: "user", content: "Current task" },
      {
        role: "assistant",
        content: [{ type: "text", text: "Work needs verification." }],
      },
    ],
  },
};
let gatekeeperCalls = 0;
const ctx = {
  cwd: process.cwd(),
  model: runtime.getModel("openai-codex", "gpt-6-sol"),
  modelRegistry: {
    async complete(_model, _context, options) {
      gatekeeperCalls++;
      assert.ok(!("onPayload" in options));
      return { content: [{ type: "text", text: "YES" }] };
    },
  },
};
const stop = handlersFor(stopHook);
const checkStop = (event = boundary) =>
  stop.get("agent_before_settle")(event, ctx);
await stop.get("input")({ source: "interactive" });
assert.equal(await checkStop(), undefined);
stop.get("tool_execution_start")();
for (const outcome of ["error", "aborted"]) {
  assert.equal(await checkStop({ ...boundary, outcome }), undefined);
}
assert.equal(await checkStop({ ...boundary, continue: true }), undefined);
assert.equal(
  await checkStop({
    ...boundary,
    context: { ...boundary.context, pendingMessages: [{}] },
  }),
  undefined,
);
assert.equal(gatekeeperCalls, 0);
const nudge = await checkStop();
assert.equal(nudge.continue, true);
assert.equal(nudge.entries[0], draft);
assert.equal(nudge.entries[1].customType, "stop-check");
await stop.get("input")({ source: "extension" });
assert.equal(await checkStop(), undefined);
assert.equal(gatekeeperCalls, 1);
await stop.get("input")({ source: "interactive" });
assert.equal(await checkStop(), undefined);
stop.get("tool_execution_start")();
assert.equal((await checkStop()).continue, true);
assert.equal(gatekeeperCalls, 2);

let checks = 0;
let exitCode = 1;
const latHandlers = handlersFor(lat, async (command, args) => {
  assert.equal(command, "lat");
  assert.deepEqual(args, ["check"]);
  checks++;
  return { code: exitCode, stdout: "check result", stderr: "", killed: false };
});
const checkLat = (event = boundary) =>
  latHandlers.get("agent_before_settle")(event, ctx);
await latHandlers.get("before_agent_start")();
for (const outcome of ["error", "aborted"])
  assert.equal(await checkLat({ ...boundary, outcome }), undefined);
assert.equal(checks, 0);
const correction = await checkLat({
  ...boundary,
  entries: nudge.entries,
  continue: true,
});
assert.equal(correction.continue, true);
assert.deepEqual(correction.entries.slice(0, 2), nudge.entries);
assert.equal(correction.entries[2].customType, "lat-check");
assert.equal(await checkLat(), undefined);
exitCode = 0;
assert.equal(await checkLat(), undefined);
assert.equal(checks, 3);
await latHandlers.get("before_agent_start")();
assert.equal(await checkLat(), undefined);
exitCode = 1;
assert.equal((await checkLat()).continue, true);
assert.equal(checks, 5);
console.log(
  "PASS: model defaults, context budgets, thinking choices, completion boundaries and bounded corrections",
);
