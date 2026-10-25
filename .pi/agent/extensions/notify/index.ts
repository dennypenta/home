/** Terminal-only completion notifications. No shell, subprocesses, or network access. */
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const ESC = "\x1b";
const ST = `${ESC}\\`;

// Strip control characters (including OSC terminators), protocol field separators,
// and bidi overrides. Bound size before emitting anything to the terminal.
export function sanitizeText(text: string): string {
  return Array.from(text.replace(/[\x00-\x1f\x7f-\x9f;\u202a-\u202e\u2066-\u2069]/g, " "))
    .slice(0, 200).join("");
}

export function wrapForTmux(sequence: string, tmux: boolean): string {
  return tmux ? `${ESC}Ptmux;${sequence.replaceAll(ESC, ESC + ESC)}${ST}` : sequence;
}

export function notificationSequence(
  env: NodeJS.ProcessEnv,
  title = "Pi",
  body = "Ready for input",
): string {
  const safeTitle = sanitizeText(title);
  const safeBody = sanitizeText(body);
  let sequences: string[];
  if (env.KITTY_WINDOW_ID) {
    // OSC 99 actions use names, not numeric flags. Disable focus and reports,
    // and send the body as the final part.
    sequences = [
      `${ESC}]99;i=pi-complete:d=0:a=-focus,-report;${safeTitle}${ST}`,
      `${ESC}]99;i=pi-complete:p=body:d=1:a=-focus,-report;${safeBody}${ST}`,
    ];
  } else if (env.TERM_PROGRAM === "iTerm.app" || env.ITERM_SESSION_ID) {
    sequences = [`${ESC}]9;${safeTitle}: ${safeBody}\x07`];
  } else {
    sequences = [`${ESC}]777;notify;${safeTitle};${safeBody}\x07`];
  }
  return sequences.map((sequence) => wrapForTmux(sequence, Boolean(env.TMUX))).join("")
    + (env.PI_NOTIFY_BELL === "1" ? "\x07" : "");
}

export default function (pi: ExtensionAPI) {
  pi.on("agent_settled", async (_event, ctx) => {
    // Never inject terminal escapes into print, JSON, RPC, or redirected output.
    if (ctx.mode !== "tui" || !process.stdout.isTTY || process.env.TERM === "dumb") return;
    if (process.env.PI_NOTIFY_DISABLED === "1") return;
    // Fixed text intentionally excludes prompts, responses, paths, and secrets.
    process.stdout.write(notificationSequence(process.env));
  });
}
