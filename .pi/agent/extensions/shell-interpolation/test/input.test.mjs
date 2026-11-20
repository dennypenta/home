import assert from "node:assert/strict";
import { registerHooks } from "node:module";
import { test } from "node:test";

const hooks = registerHooks({
  resolve(specifier, context, nextResolve) {
    if (specifier === "@earendil-works/pi-coding-agent") {
      return {
        url: `data:text/javascript,${encodeURIComponent(`
          export const getShellConfig = () => ({ shell: "/bin/bash", args: ["-c"] });
          export const stripFrontmatter = text => text;
        `)}`,
        shortCircuit: true,
      };
    }
    return nextResolve(specifier, context);
  },
});
const { default: register } = await import("../index.ts");
hooks.deregister();

async function run(result, text = "Analyze !!(tests) then !!(next)") {
  let handler;
  const notifications = [];
  const commands = [];
  register({
    on: (name, callback) => { handler = callback; },
    getSettings: () => ({}),
    exec: async (_shell, args) => {
      commands.push(args.at(-1));
      return result;
    },
  });
  const images = [];
  const response = await handler({ source: "interactive", text, images }, {
    cwd: process.cwd(),
    hasUI: true,
    ui: { notify: message => notifications.push(message) },
  });
  return { response, notifications, commands, images };
}

test("nonzero exits interpolate stdout and stderr and continue", async () => {
  const { response, notifications, commands, images } = await run({
    code: 1, killed: false, stdout: "FAIL test", stderr: "assertion failed\n",
  });
  assert.deepEqual(response, {
    action: "transform",
    text: "Analyze FAIL test\nassertion failed then FAIL test\nassertion failed",
    images,
  });
  assert.deepEqual(notifications, []);
  assert.deepEqual(commands, ["tests", "next"]);
});

test("stderr-only nonzero exits remain visible", async () => {
  const { response } = await run({ code: 2, killed: false, stdout: "", stderr: "test error\n" }, "!!(tests)");
  assert.equal(response.text, "test error");
});

test("killed commands still stop submission", async () => {
  const { response, commands, notifications } = await run({ code: 1, killed: true, stdout: "", stderr: "" });
  assert.equal(response.action, "handled");
  assert.deepEqual(commands, ["tests"]);
  assert.match(notifications[0], /cancelled or timed out/);
});

test("failed command output still has a size limit", async () => {
  const { response, notifications } = await run({ code: 1, killed: false, stdout: "", stderr: "x".repeat(1024 * 1024 + 1) });
  assert.equal(response.action, "handled");
  assert.match(notifications[0], /exceeds 1 MiB/);
});
