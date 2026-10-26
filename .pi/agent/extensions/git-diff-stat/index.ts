import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";
import { truncateToWidth } from "@earendil-works/pi-tui";
import { collectStats, displayPath } from "./core.ts";

const WIDGET = "git-diff-stat";
const LIMIT = 4;

export default function (pi: ExtensionAPI) {
  let stop: (() => void) | undefined;
  let refresh: (() => Promise<void>) | undefined;

  function start(ctx: ExtensionContext) {
    stop?.();
    if (ctx.mode !== "tui") return;

    const controller = new AbortController();
    let running = false;
    let previous: string | undefined;
    let active = true;

    refresh = async () => {
      if (!active || running) return;
      running = true;
      try {
        const options = { cwd: ctx.cwd, timeout: 5000, signal: controller.signal };
        const root = await pi.exec("git", ["rev-parse", "--show-toplevel"], options);
        if (root.code !== 0) throw new Error("Not a Git repository");
        const files = await collectStats((args) => pi.exec("git", args, {
          ...options, cwd: root.stdout.replace(/\r?\n$/, ""),
        }));
        if (!active) return;
        const output = JSON.stringify(files);
        if (output === previous) return;
        previous = output;
        if (!files.length) {
          ctx.ui.setWidget(WIDGET, undefined);
          return;
        }
        ctx.ui.setWidget(WIDGET, (_tui, theme) => ({
          render(width) {
            const hidden = files.length - LIMIT;
            const heading = `git diff --stat · ${files.length} file${files.length === 1 ? "" : "s"}`
              + (hidden > 0 ? ` · top ${LIMIT}, ${hidden} more` : "");
            return [
              theme.fg("muted", heading),
              ...files.slice(0, LIMIT).map((file) => {
                const counts = file.binary
                  ? theme.fg("dim", "binary")
                  : `${file.added + file.deleted} ${theme.fg("success", `+${file.added}`)} ${theme.fg("error", `-${file.deleted}`)}`;
                return `  ${counts} | ${displayPath(file.path)}`;
              }),
            ].map((line) => truncateToWidth(line, width));
          },
          invalidate() {},
        }));
      } catch {
        if (active) {
          previous = undefined;
          ctx.ui.setWidget(WIDGET, undefined);
        }
      } finally {
        running = false;
      }
    };

    // Polling also catches edits made outside Pi. Avoid overlapping Git processes.
    const timer = setInterval(() => { void refresh?.(); }, 2000);
    timer.unref();
    stop = () => {
      active = false;
      clearInterval(timer);
      controller.abort();
      ctx.ui.setWidget(WIDGET, undefined);
      refresh = undefined;
      stop = undefined;
    };
    void refresh();
  }

  pi.on("session_start", (_event, ctx) => start(ctx));
  pi.on("tool_execution_end", async () => { await refresh?.(); });
  pi.on("agent_end", async () => { await refresh?.(); });
  pi.on("session_shutdown", () => stop?.());
}
