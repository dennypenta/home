import { test } from "node:test";
import assert from "node:assert/strict";
import { createSessionToggle } from "../core.ts";

function setup() {
  const tools = new Map();
  let active = new Set();
  const pi = {
    registerTool(tool) {
      tools.set(tool.name, tool);
      if (!tool.exposure || tool.exposure === "direct") active.add(tool.name);
    },
    getActiveTools: () => [...active],
    setActiveTools: (names) => { active = new Set(names); },
    getMcpServers: () => [],
  };
  const toggle = createSessionToggle(pi);
  toggle.configure([{ name: "paper" }, { name: "other" }]);
  const tool = (name, exposure = "deferred", server = "paper") => ({
    name, exposure, namespace: { name: `mcp__${server}` }, execute: async () => ({}),
  });
  return { pi, toggle, tools, tool };
}

test("hides discovery exposure and restores only previously active declarations", () => {
  const { pi, toggle, tools, tool } = setup();
  toggle.api.registerTool(tool("a"));
  toggle.api.registerTool(tool("b", "direct"));
  toggle.api.registerTool(tool("c", "hidden"));
  toggle.api.registerTool(tool("d", "direct"));
  pi.setActiveTools(["read", "a", "b"]); // d deliberately inactive
  assert.equal(toggle.setVisible("paper", false), "paper");
  for (const name of ["a", "b", "c", "d"]) assert.equal(tools.get(name).exposure, "hidden");
  assert.deepEqual(pi.getActiveTools(), ["read"]);
  toggle.setVisible("paper", true);
  assert.equal(tools.get("a").exposure, "deferred");
  assert.equal(tools.get("c").exposure, "hidden");
  assert.deepEqual(pi.getActiveTools(), ["read", "a", "b"]);
});

test("late arrivals and withdrawals while off retain their latest real exposure", () => {
  const { pi, toggle, tools, tool } = setup();
  toggle.setVisible("paper", false);
  toggle.api.registerTool(tool("late", "direct"));
  toggle.api.registerTool(tool("gone", "deferred"));
  toggle.api.registerTool(tool("gone", "hidden"));
  assert.equal(tools.get("late").exposure, "hidden");
  toggle.setVisible("paper", true);
  assert.equal(tools.get("late").exposure, "direct");
  assert.equal(tools.get("gone").exposure, "hidden");
  assert.deepEqual(pi.getActiveTools(), ["late"]);
});

test("filters prompt listing and removes empty MCP section", () => {
  const { toggle } = setup();
  toggle.setVisible("paper", false);
  const event = { systemPromptOptions: { sections: { mcp_servers: "Intro\n- mcp__paper (codemode): Paper\n- mcp__other (codemode): Other" } } };
  toggle.filterPrompt(event);
  assert.equal(event.systemPromptOptions.sections.mcp_servers, "Intro\n- mcp__other (codemode): Other");
  toggle.setVisible("other", false);
  toggle.filterPrompt(event);
  assert.equal(event.systemPromptOptions.sections.mcp_servers, undefined);
});

test("unknown names, aliases, repeated commands and session reset", () => {
  const { toggle } = setup();
  toggle.configure([{ name: "dev-radius" }]);
  assert.equal(toggle.setVisible("missing", false), undefined);
  assert.equal(toggle.setVisible("dev_radius", false), "dev-radius");
  assert.equal(toggle.setVisible("dev-radius", false), "dev-radius");
  toggle.reset();
  assert.deepEqual(toggle.names(), []);
});

test("status reflects session masks, restoration, aliases, and reset without changing tools", () => {
  const { pi, toggle, tools, tool } = setup();
  toggle.configure([{ name: "dev-radius" }]);
  toggle.api.registerTool(tool("a", "direct"));
  const active = pi.getActiveTools();
  assert.match(toggle.status(), /paper: ON — configured visibility/);
  assert.deepEqual(pi.getActiveTools(), active);
  assert.equal(tools.get("a").exposure, "direct");
  toggle.setVisible("paper", false);
  toggle.setVisible("dev_radius", false);
  assert.match(toggle.status(), /paper: OFF — hidden in this session/);
  assert.match(toggle.status(), /dev-radius: OFF — hidden in this session/);
  assert.match(toggle.status(), /other: ON — configured visibility/);
  toggle.setVisible("paper", true);
  assert.match(toggle.status(), /paper: ON — configured visibility/);
  toggle.reset();
  assert.equal(toggle.status(), "No MCP servers configured or registered.");
  toggle.configure([{ name: "paper" }]);
  assert.match(toggle.status(), /paper: ON — configured visibility/);
});

test("shared resources filter hidden servers and reject explicit access", async () => {
  const { toggle, tools } = setup();
  toggle.api.registerTool({
    name: "list_mcp_resources", exposure: "deferred",
    execute: async () => ({ content: [], structuredContent: {
      resources: [{ server: "paper", uri: "secret" }, { server: "other", uri: "public" }],
      errors: [{ server: "paper", error: "private" }],
    } }),
  });
  toggle.setVisible("paper", false);
  const result = await tools.get("list_mcp_resources").execute("id", {});
  assert.deepEqual(result.structuredContent, { resources: [{ server: "other", uri: "public" }], errors: [] });
  assert.equal(JSON.stringify(result).includes("secret"), false);
  await assert.rejects(tools.get("list_mcp_resources").execute("id", { server: "paper" }), /hidden/);
  toggle.setVisible("other", false);
  assert.equal(tools.get("list_mcp_resources").exposure, "hidden");
});
