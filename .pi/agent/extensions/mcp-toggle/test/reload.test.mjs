import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, readFile, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { pathToFileURL } from "node:url";

// Optional integration test against an installed Pi, with no session or MCP connections.
const packageDir = process.env.PI_PACKAGE_DIR;
test("Pi reload refreshes the helper used by /mcp:status", { skip: !packageDir }, async () => {
  const { loadExtensions } = await import(pathToFileURL(join(packageDir, "dist/core/extensions/loader.js")).href);
  const dir = await mkdtemp(join(tmpdir(), "mcp-toggle-reload-"));
  try {
    const entry = join(dir, "index.ts");
    await writeFile(entry, await readFile(new URL("../index.ts", import.meta.url), "utf8"));
    const original = await readFile(new URL("../core.ts", import.meta.url), "utf8");
    for (const expected of ["No MCP servers configured or registered.", "Reloaded helper."]) {
      await writeFile(join(dir, "core.ts"), original.replace("No MCP servers configured or registered.", expected));
      const result = await loadExtensions([entry], dir);
      assert.deepEqual(result.errors, []);
      const commands = result.extensions[0].commands;
      for (const name of ["mcp", "mcp:on", "mcp:off", "mcp:status"]) assert.ok(commands.has(name));
      const notifications = [];
      await commands.get("mcp:status").handler("", {
        ui: { notify: (message) => notifications.push(message) },
      });
      assert.deepEqual(notifications, [expected]);
    }
  } finally {
    await rm(dir, { recursive: true, force: true });
  }
});
