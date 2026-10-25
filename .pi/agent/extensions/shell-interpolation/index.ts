import { readFile } from "node:fs/promises";
import { getShellConfig, stripFrontmatter, type ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { interpolate, parseArgs, substituteArgs } from "./core.mjs";

export default function (pi: ExtensionAPI) {
  pi.on("input", async (event, ctx) => {
    // Never execute shell markers in messages injected by other extensions.
    if (event.source === "extension") return { action: "continue" };

    try {
      let text = event.text;
      const invocation = text.match(/^\/([^\s]+)(?:\s+([\s\S]*))?$/);
      if (invocation) {
        // Use only templates Pi already discovered (including its trust checks).
        const command = pi.getCommands().find((item) => item.name === invocation[1]);
        if (command?.source === "prompt") {
          const body = stripFrontmatter(await readFile(command.sourceInfo.path, "utf8"));
          const expanded = substituteArgs(body, parseArgs(invocation[2] ?? ""));
          // Leave ordinary templates entirely to Pi.
          if (!expanded.includes("!!(")) return { action: "continue" };
          text = expanded;
        }
      }
      if (!text.includes("!!(")) return { action: "continue" };

      const shell = getShellConfig(pi.getSettings().shellPath);
      if (shell.commandTransport === "stdin") {
        throw new Error("Shell interpolation requires an argv-based shell (configure shellPath to Bash)");
      }
      const expanded = await interpolate(text, async (command: string) => {
        const result = await pi.exec(shell.shell, [...shell.args, command], {
          cwd: ctx.cwd,
          timeout: 30_000,
          signal: ctx.signal,
        });
        if (result.killed || result.code !== 0) {
          throw new Error(`Shell interpolation ${result.killed ? "cancelled or timed out" : `exited with code ${result.code}`}: ${command}\n${result.stderr.trim()}`);
        }
        if (Buffer.byteLength(result.stdout, "utf8") > 1024 * 1024) {
          throw new Error(`Shell interpolation output exceeds 1 MiB: ${command}`);
        }
        return result.stdout;
      });
      return { action: "transform", text: expanded, images: event.images };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      ctx.ui.notify(message, "error");
      if (!ctx.hasUI) console.error(`[shell-interpolation] ${message}`);
      // Input hook errors normally fall through: explicitly consume failed input.
      return { action: "handled" };
    }
  });
}
