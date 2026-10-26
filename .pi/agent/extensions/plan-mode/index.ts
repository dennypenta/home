import { mkdir, writeFile } from "node:fs/promises";
import { join } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const READ_ONLY = ["read", "grep", "find", "ls"];
export const OPTIONS = [
  "1. Accept and execute in this session",
  "2. Accept and execute in a new session",
  "3. Keep the plan without executing",
];
const INSTRUCTIONS = `You are in read-only planning mode. Investigate the request using the available read-only tools. Do not implement changes or run commands. Return a self-contained Markdown implementation plan as your final response, with the goal, relevant files and findings, numbered implementation steps, risks or open questions, and verification/tests. Include enough context to execute it in a fresh session. The extension will save your final response; do not write the plan yourself.`;

export async function savePlan(cwd: string, text: string, now = new Date()): Promise<string> {
  const directory = join(cwd, ".pi", "plans");
  await mkdir(directory, { recursive: true });
  const stamp = now.toISOString().replace(/[:.]/g, "-");
  for (let suffix = 0; ; suffix++) {
    const path = join(directory, `${stamp}${suffix ? `-${suffix}` : ""}.md`);
    try {
      await writeFile(path, `${text.trim()}\n`, { flag: "wx" });
      return path;
    } catch (error) {
      if ((error as NodeJS.ErrnoException).code !== "EEXIST") throw error;
    }
  }
}

export default function planMode(pi: ExtensionAPI): void {
  let active: {
    tools: string[];
    text: string;
    failed: boolean;
    finish: (aborted: boolean) => void;
    ctx: ExtensionContext;
  } | undefined;

  function release(): void {
    if (!active) return;
    const state = active;
    active = undefined;
    pi.setActiveTools(state.tools);
    state.ctx.ui.setStatus("plan-mode", undefined);
  }

  pi.on("tool_call", (event) => {
    if (active && !READ_ONLY.includes(event.toolName)) {
      return { block: true, reason: "Plan mode only permits read, grep, find, and ls." };
    }
  });
  pi.on("before_agent_start", () => {
    if (active) {
      pi.setActiveTools(READ_ONLY);
      return { message: { customType: "plan-mode-context", content: INSTRUCTIONS, display: false } };
    }
  });
  pi.on("context", (event) => {
    if (!active) return {
      messages: event.messages.filter((message) => !("customType" in message && message.customType === "plan-mode-context")),
    };
  });
  pi.on("session_start", (_event, ctx) => {
    const entry = ctx.sessionManager.getBranch().find((entry) => entry.type === "custom" && entry.customType === "plan-execution-tools");
    if (entry?.type === "custom" && Array.isArray(entry.data) && entry.data.every((name) => typeof name === "string")) {
      pi.setActiveTools([...new Set([...pi.getActiveTools(), ...entry.data])]);
    }
  });
  pi.on("message_end", (event) => {
    if (!active || event.message.role !== "assistant") return;
    active.failed = event.message.stopReason === "error" || event.message.stopReason === "aborted";
    active.text = event.message.content.filter((part) => part.type === "text").map((part) => part.text).join("\n");
  });
  // Resolve only: session replacement and waiting for idle must happen in the command, not a lifecycle hook.
  pi.on("agent_settled", (event) => active?.finish(event.aborted));
  pi.on("session_shutdown", () => {
    const state = active;
    release();
    state?.finish(true);
  });

  pi.registerCommand("plan", {
    description: "Create a read-only plan: /plan <request>",
    handler: async (args, ctx) => {
      const request = args.trim();
      if (!request) return ctx.ui.notify("Usage: /plan <request>", "warning");
      if (active || !ctx.isIdle() || ctx.hasPendingMessages()) {
        return ctx.ui.notify("Wait for the current operation to finish before planning.", "warning");
      }
      if (!ctx.model) return ctx.ui.notify("Select a model before planning.", "error");
      let finish!: (aborted: boolean) => void;
      const settled = new Promise<boolean>((resolve) => { finish = resolve; });
      const state = { tools: pi.getActiveTools(), text: "", failed: false, finish, ctx };
      active = state;
      pi.setActiveTools(READ_ONLY);
      ctx.ui.setStatus("plan-mode", "plan (read-only)");
      try {
        // The explicit user prompt keeps the restriction even if context hooks remove older mode messages.
        pi.sendUserMessage(`${INSTRUCTIONS}\n\n## Request\n\n${request}`);
        const aborted = await settled;
        if (active !== state) return; // Runtime was replaced or shut down.
        await ctx.waitForIdle();
        if (aborted || state.failed || !state.text.trim()) {
          ctx.ui.notify("Planning stopped; no plan was saved or executed.", "warning");
          return;
        }
        const path = await savePlan(ctx.cwd, state.text);
        pi.sendMessage({ customType: "saved-plan", content: `Plan saved to \`${path}\`\n\n${state.text}`, display: true });
        const choice = ctx.hasUI ? await ctx.ui.select("Plan saved — what next?", OPTIONS) : undefined;
        const prompt = `Execute the accepted implementation plan below. Make the changes and run the relevant verification.\n\nPlan file: ${path}\n\n${state.text}`;
        // Restore the previous loadout and enable built-in editing tools only after explicit acceptance.
        const tools = [...new Set([...state.tools, "edit", "write", "bash"])];
        const parentSession = ctx.sessionManager.getSessionFile();
        release();
        if (choice === OPTIONS[0]) {
          pi.setActiveTools(tools);
          pi.sendUserMessage(prompt);
        } else if (choice === OPTIONS[1]) {
          const result = await ctx.newSession({
            parentSession,
            setup: async (manager) => { manager.appendCustomEntry("plan-execution-tools", tools); },
            withSession: async (replacement) => {
              // The replacement runtime starts with its normal tool loadout.
              await replacement.sendUserMessage(prompt);
            },
          });
          if (result.cancelled) ctx.ui.notify("New session cancelled; the saved plan is unchanged.", "info");
        }
      } catch (error) {
        if (active === state) ctx.ui.notify(`Plan mode failed: ${error instanceof Error ? error.message : String(error)}`, "error");
        else throw error;
      } finally {
        if (active === state) release();
      }
    },
  });
}
