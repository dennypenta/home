const resourceNames = new Set([
  "list_mcp_resources", "list_mcp_resource_templates", "read_mcp_resource",
]);
const namespace = (name) => `mcp__${name.replace(/-/g, "_")}`;

/** Wrap only MCP's registrations; never replace unrelated extensions' tools. */
export function createSessionToggle(pi) {
  const disabled = new Set();
  const definitions = new Map();
  const previouslyActive = new Set();
  const configured = new Set();
  let registered = new Set();

  const names = () => [...new Set([...configured, ...registered])].sort();
  const owner = (tool) => names().find((name) => tool.namespace?.name === namespace(name));
  const allHidden = () => names().length > 0 && names().every((name) => disabled.has(name));
  const isHidden = (tool) => disabled.has(owner(tool)) || (resourceNames.has(tool.name) && allHidden());

  function publish(definition) {
    let tool = definition;
    if (resourceNames.has(tool.name)) {
      // Shared resource tools must not reveal a hidden server through discovery either.
      tool = { ...tool, async execute(id, args, ...rest) {
        if (disabled.has(args?.server)) throw new Error(`MCP server "${args.server}" is hidden in this session.`);
        const result = await definition.execute(id, args, ...rest);
        if (tool.name === "read_mcp_resource" || !disabled.size) return result;
        const payload = result.structuredContent;
        if (!payload || typeof payload !== "object") return result;
        const filtered = Object.fromEntries(Object.entries(payload).map(([key, value]) => [
          key, Array.isArray(value) ? value.filter((item) => !disabled.has(item?.server)) : value,
        ]));
        return { ...result, structuredContent: filtered, content: [{ type: "text", text: JSON.stringify(filtered) }] };
      } };
    }
    pi.registerTool(isHidden(tool) ? { ...tool, exposure: "hidden" } : tool);
  }

  const api = new Proxy(pi, { get(target, key) {
    if (key === "registerTool") return (tool) => {
      definitions.set(tool.name, tool);
      if (isHidden(tool) && (!tool.exposure || tool.exposure === "direct")) previouslyActive.add(tool.name);
      publish(tool);
    };
    if (key === "getMcpServers") return () => {
      const servers = target.getMcpServers();
      registered = new Set(servers.map((server) => server.name));
      return servers;
    };
    return Reflect.get(target, key);
  } });

  function setVisible(name, visible) {
    const resolved = names().find((candidate) => namespace(candidate) === namespace(name));
    if (!resolved) return undefined;
    if (visible === !disabled.has(resolved)) return resolved;
    if (visible) disabled.delete(resolved);
    else disabled.add(resolved);
    const active = new Set(pi.getActiveTools());
    for (const tool of definitions.values()) {
      if (isHidden(tool) && active.has(tool.name)) previouslyActive.add(tool.name);
      publish(tool);
    }
    const current = new Set(active);
    for (const tool of definitions.values()) {
      if (isHidden(tool)) current.delete(tool.name);
      else if (previouslyActive.delete(tool.name) && tool.exposure !== "hidden") current.add(tool.name);
    }
    pi.setActiveTools([...current]);
    return resolved;
  }

  function filterPrompt(event) {
    const sections = event.systemPromptOptions.sections;
    const section = sections.mcp_servers;
    if (!section || !disabled.size) return;
    // Preserve the built-in intro and descriptions of visible servers.
    const lines = section.split("\n").filter((line) => ![...disabled].some((name) => line.startsWith(`- ${namespace(name)} (`)));
    if (lines.some((line) => line.startsWith("- mcp__"))) sections.mcp_servers = lines.join("\n");
    else delete sections.mcp_servers;
  }

  return {
    api, names, setVisible, filterPrompt,
    status() {
      const servers = names();
      if (!servers.length) return "No MCP servers configured or registered.";
      return [
        "MCP session visibility:",
        ...servers.map((name) => `${name}: ${disabled.has(name) ? "OFF — hidden in this session" : "ON — configured visibility"}`),
        "",
        "ON removes the session mask; configured disabled/hidden tools remain unavailable.",
        "Earlier conversation history is unchanged.",
      ].join("\n");
    },
    blockCall(event) {
      const tool = definitions.get(event.toolName);
      if ((tool && isHidden(tool)) || (resourceNames.has(event.toolName) && disabled.has(event.input?.server))) {
        return { block: true, reason: "This MCP server is hidden in the current session." };
      }
    },
    configure(entries) { for (const entry of entries) configured.add(entry.name); },
    reset() { disabled.clear(); definitions.clear(); previouslyActive.clear(); configured.clear(); registered.clear(); },
  };
}
