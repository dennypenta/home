import assert from "node:assert/strict";
import { mkdtemp, readFile, readdir, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import planMode, { OPTIONS, savePlan } from "./index.ts";

async function harness(choice?: string) {
  const cwd = await mkdtemp(join(tmpdir(), "pi-plan-"));
  const handlers = new Map<string, Function>();
  let command: Function;
  let tools = ["read", "bash", "edit", "write", "custom"];
  const prompts: string[] = [];
  const displayed: any[] = [];
  const notices: string[] = [];
  let switched = false;
  let outcome = "stop";
  let aborted = false;
  let selectionCount = 0;
  const pi = {
    on: (name: string, fn: Function) => handlers.set(name, fn),
    registerCommand: (_name: string, config: any) => { command = config.handler; },
    getActiveTools: () => [...tools],
    setActiveTools: (value: string[]) => { tools = value; },
    sendMessage: (message: any) => displayed.push(message),
    sendUserMessage: (text: string) => {
      prompts.push(text);
      if (prompts.length !== 1) return;
      queueMicrotask(() => {
        handlers.get("message_end")!({ message: { role: "assistant", stopReason: outcome, content: [{ type: "text", text: "# Plan\n\n1. Add a test.\n2. Implement." }] } });
        handlers.get("agent_settled")!({ aborted });
      });
    },
  };
  const ctx: any = {
    cwd, model: {}, hasUI: true, isIdle: () => true, hasPendingMessages: () => false,
    waitForIdle: async () => {},
    sessionManager: { getSessionFile: () => "parent.jsonl", getBranch: () => [] },
    ui: {
      setStatus: () => {}, notify: (message: string) => notices.push(message),
      select: async (_title: string, options: string[]) => {
        selectionCount++;
        assert.deepEqual(options, OPTIONS);
        assert.equal((await readdir(join(cwd, ".pi/plans"))).length, 1);
        assert.equal(displayed.length, 1);
        assert.deepEqual(tools, ["read", "grep", "find", "ls"]);
        return choice;
      },
    },
    newSession: async (options: any) => {
      switched = true;
      assert.equal(options.parentSession, "parent.jsonl");
      const entries: any[] = [];
      await options.setup({ appendCustomEntry: (customType: string, data: any) => entries.push({ type: "custom", customType, data }) });
      tools = ["read"];
      handlers.get("session_start")!({}, { sessionManager: { getBranch: () => entries } });
      assert.ok(tools.includes("edit") && tools.includes("write") && tools.includes("bash"));
      await options.withSession({ sendUserMessage: async (text: string) => prompts.push(text) });
      return { cancelled: false };
    },
  };
  planMode(pi as any);
  return {
    cwd, handlers, ctx, prompts, displayed, notices,
    run: (request = "add a feature") => command!(request, ctx),
    tools: () => tools, switched: () => switched, selections: () => selectionCount,
    fail: () => { outcome = "error"; }, abort: () => { aborted = true; },
    cleanup: () => rm(cwd, { recursive: true, force: true }),
  };
}

for (const choice of [...OPTIONS, undefined]) {
  test(`plan workflow: ${choice ?? "dismiss"}`, async () => {
    const h = await harness(choice);
    try {
      const running = h.run();
      for (const name of ["bash", "write", "edit", "codemode", "custom"]) {
        assert.equal(h.handlers.get("tool_call")!({ toolName: name })?.block, true);
      }
      assert.equal(h.handlers.get("tool_call")!({ toolName: "read" }), undefined);
      await running;
      assert.equal(h.selections(), 1);
      assert.equal(h.switched(), choice === OPTIONS[1]);
      const executes = choice === OPTIONS[0] || choice === OPTIONS[1];
      assert.equal(h.prompts.length, executes ? 2 : 1);
      if (executes) assert.match(h.prompts[1], /# Plan/);
      assert.ok(h.tools().includes("write"));
      assert.equal(h.handlers.get("tool_call")!({ toolName: "write" }), undefined);
    } finally { await h.cleanup(); }
  });
}

for (const failure of ["fail", "abort"] as const) {
  test(`${failure} does not save or execute`, async () => {
    const h = await harness(OPTIONS[0]);
    try {
      h[failure]();
      await h.run();
      assert.equal(h.selections(), 0);
      assert.equal(h.prompts.length, 1);
      await assert.rejects(readdir(join(h.cwd, ".pi/plans")), { code: "ENOENT" });
      assert.ok(h.tools().includes("custom"));
    } finally { await h.cleanup(); }
  });
}

test("usage and busy sessions do not start planning", async () => {
  const h = await harness();
  try {
    await h.run(" ");
    h.ctx.isIdle = () => false;
    await h.run();
    assert.equal(h.prompts.length, 0);
  } finally { await h.cleanup(); }
});

test("save failures restore tools without offering execution", async () => {
  const h = await harness(OPTIONS[0]);
  try {
    h.ctx.cwd = import.meta.filename; // A file cannot contain .pi/plans.
    await h.run();
    assert.equal(h.selections(), 0);
    assert.equal(h.prompts.length, 1);
    assert.equal(h.displayed.length, 0);
    assert.ok(h.tools().includes("custom"));
    assert.ok(h.notices.some((message) => message.startsWith("Plan mode failed:")));
  } finally { await h.cleanup(); }
});

test("session shutdown cancels pending planning without saving", async () => {
  const h = await harness(OPTIONS[0]);
  try {
    const running = h.run();
    h.handlers.get("session_shutdown")!();
    await running;
    assert.equal(h.selections(), 0);
    assert.equal(h.prompts.length, 1);
    assert.ok(h.tools().includes("custom"));
  } finally { await h.cleanup(); }
});

test("timestamped plans never overwrite a prior plan", async () => {
  const cwd = await mkdtemp(join(tmpdir(), "pi-plan-save-"));
  try {
    const now = new Date("2026-01-02T03:04:05.000Z");
    const a = await savePlan(cwd, "first", now);
    const b = await savePlan(cwd, "second", now);
    assert.notEqual(a, b);
    assert.equal(await readFile(a, "utf8"), "first\n");
    assert.equal(await readFile(b, "utf8"), "second\n");
    assert.match(a, /2026-01-02T03-04-05-000Z\.md$/);
  } finally { await rm(cwd, { recursive: true, force: true }); }
});
