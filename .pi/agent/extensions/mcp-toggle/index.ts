import { join } from "node:path";
import { pathToFileURL } from "node:url";
import { getAgentDir, getPackageDir, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
// Keep local helpers in TypeScript: native .mjs imports remain cached across /reload.
import { createSessionToggle } from "./core.ts";

export default async function (pi: ExtensionAPI) {
  // Pi has no public setter for another extension's tool exposure. Delegate to
  // its installed MCP implementation, intercepting registrations instead of
  // copying the client, authentication, project-trust, or transport logic.
  const base = join(getPackageDir(), "dist/extensions/mcp");
  const [{ createMcpExtension }, { loadMcpConfig }] = await Promise.all([
    import(pathToFileURL(join(base, "index.js")).href),
    import(pathToFileURL(join(base, "config.js")).href),
  ]);
  const toggle = createSessionToggle(pi);
  pi.on("session_start", () => toggle.reset());
  await createMcpExtension({
    loadConfig(ctx: { cwd: string; isProjectTrusted(): boolean }) {
      const loaded = loadMcpConfig({
        agentDir: getAgentDir(), cwd: ctx.cwd, projectTrusted: ctx.isProjectTrusted(),
      });
      toggle.configure(loaded.servers);
      return loaded;
    },
  })(toggle.api);
  // Registering the delegated /mcp intentionally replaces the built-in MCP
  // extension, so there is one connection and one owner for every MCP tool.
  pi.on("before_agent_start", (event) => toggle.filterPrompt(event));
  pi.on("tool_call", (event) => toggle.blockCall(event));

  pi.registerCommand("mcp:status", {
    description: "Show MCP server visibility in this session",
    async handler(args, ctx) {
      if (args.trim()) {
        ctx.ui.notify("Usage: /mcp:status", "warning");
        return;
      }
      ctx.ui.notify(toggle.status(), "info");
    },
  });

  for (const [command, visible] of [["mcp:on", true], ["mcp:off", false]] as const) {
    pi.registerCommand(command, {
      description: `${visible ? "Show" : "Hide"} an MCP server's tools for this session only`,
      getArgumentCompletions(prefix) {
        return toggle.names().filter((name: string) => name.startsWith(prefix.trim()))
          .map((name: string) => ({ value: name, label: name }));
      },
      async handler(args, ctx) {
        const name = args.trim();
        if (!name || /\s/.test(name)) {
          ctx.ui.notify(`Usage: /${command} <server>\nServers: ${toggle.names().join(", ") || "none"}`, "warning");
          return;
        }
        if (!ctx.isIdle()) {
          ctx.ui.notify("Wait for the current run to finish before toggling MCP tools.", "warning");
          return;
        }
        const server = toggle.setVisible(name, visible);
        if (!server) {
          ctx.ui.notify(`Unknown MCP server: ${name}. Servers: ${toggle.names().join(", ") || "none"}`, "error");
          return;
        }
        ctx.ui.notify(`${server}: tools ${visible ? "restored to configured visibility" : "hidden"} for this session. No configuration changed.`, "info");
      },
    });
  }
}
