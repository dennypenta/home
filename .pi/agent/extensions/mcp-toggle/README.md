# Session-only MCP visibility

Commands:

```text
/mcp:off paper    Hide Paper's tools in this session
/mcp:on paper     Restore their configured visibility
/mcp:status       Show ON/OFF session visibility for every server
```

Server names autocomplete. Run either command without an argument to see known
servers. Hyphen/underscore aliases are accepted. Visibility changes require an
idle agent; `/mcp:status` is read-only and can be used during a run. Status reports
the session mask, not connection health: ON still respects configured disabled
servers and hidden tools. It does not add a message to the model's context.

## Load

This directory is auto-discovered when installed under `~/.pi/agent/extensions/`.
Run `/reload` in an existing Pi session to load it. For a one-off installation:

```sh
pi --extension /absolute/path/to/mcp-toggle/index.ts
```

## Behavior

- No `mcp.json` or settings files are written by these two commands.
- Hides direct declarations **and** codemode/tool-search discovery and execution.
- Removes the server's entry from the next prompt's `mcp_servers` section.
- Handles tools arriving later, reconnects, and changed/withdrawn tools.
- Filters hidden servers out of shared resource listings; explicit resource
  access is blocked. Shared resource tools are hidden when all servers are hidden.
- Restores original tool exposures and previously active declarations, rather than
  promoting all tools to direct exposure.
- Keeps connections running; this is a visibility switch, not a process manager.
- `/new`, session replacement, and `/reload` reset the switches. They are not
  persisted in session files or inherited when resuming a session.
- `/mcp:on` removes this extension's visibility mask. It does not connect a server
  that is disabled in configuration, nor expose a tool configured as hidden.

Already-recorded messages, tool outputs, and earlier tool/prompt declarations are
**not erased from conversation history**. Hiding stops future exposure; it is not
retroactive redaction or guaranteed reclamation of all historical tokens. Use
compaction or a fresh session when historical context also needs to shrink.

## Integration and compatibility

Tested with Pi **1.4.0**. Pi's public active-tool setter cannot hide tools from
codemode, and its public API cannot change another extension's tool exposure.
This extension therefore delegates to the installed Pi MCP implementation using
`getPackageDir()` and internal `dist/extensions/mcp` modules, intercepting tool
registrations. These internal paths/interfaces may change in future Pi releases;
standalone binaries without these modules are not supported.

The delegated `/mcp` command intentionally replaces Pi's built-in MCP extension
(the documented replacement mechanism), avoiding duplicate server connections.
Authentication, configuration loading, project trust, and transport handling stay
with Pi. The regular `/mcp` UI remains available and **its normal configuration
changes still persist**. Do not combine this with another replacement MCP adapter.

Shared resource enumeration may still query connected hidden servers internally,
but their entries are filtered before results reach the model.

Local implementation files use `.ts` so Pi's loader refreshes them on `/reload`.
Native `.mjs` helper imports can stay cached across reloads, producing a mixture
of old helpers and new command handlers.

## Tests

```sh
node --test extensions/mcp-toggle/test/*.test.mjs
```

Set `PI_PACKAGE_DIR` to the installed `@earendil-works/pi-coding-agent` package
root to also run the integration test. It loads `/mcp:status`, modifies its helper,
and reloads it in the same process to verify that updated code takes effect.
The integration test is skipped when that variable is unset.
