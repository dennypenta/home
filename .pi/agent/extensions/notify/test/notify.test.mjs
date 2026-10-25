import assert from "node:assert/strict";
import { test } from "node:test";
import notify, { notificationSequence, sanitizeText, wrapForTmux } from "../index.ts";

const esc = "\x1b";
const st = `${esc}\\`;

test("default OSC 777 notification", () => {
  assert.equal(notificationSequence({}), `${esc}]777;notify;Pi;Ready for input\x07`);
});

test("iTerm uses OSC 9", () => {
  for (const env of [{ TERM_PROGRAM: "iTerm.app" }, { ITERM_SESSION_ID: "yes" }]) {
    assert.equal(notificationSequence(env), `${esc}]9;Pi: Ready for input\x07`);
  }
});

test("Kitty uses valid action metadata to disable activation actions", () => {
  // OSC 99 accepts focus/report and their negative forms, not numeric a=0.
  // Unknown action values may cause a conforming terminal to reject the OSC.
  assert.equal(notificationSequence({ KITTY_WINDOW_ID: "1" }),
    `${esc}]99;i=pi-complete:d=0:a=-focus,-report;Pi${st}`
    + `${esc}]99;i=pi-complete:p=body:d=1:a=-focus,-report;Ready for input${st}`);
});

test("tmux doubles all inner escapes and wraps each part separately", () => {
  assert.equal(wrapForTmux(`${esc}]9;hello${st}`, true),
    `${esc}Ptmux;${esc}${esc}]9;hello${esc}${esc}\\${st}`);
  const plain = notificationSequence({ KITTY_WINDOW_ID: "1" });
  const parts = plain.split(st).filter(Boolean).map((part) => part + st);
  assert.equal(notificationSequence({ KITTY_WINDOW_ID: "1", TMUX: "yes" }),
    parts.map((part) => wrapForTmux(part, true)).join(""));
});

test("untrusted text cannot terminate OSC or inject fields", () => {
  const hostile = "hi;\x1b]52;c;secret\x07\x9c\n\u202e";
  assert.doesNotMatch(sanitizeText(hostile), /[;\x00-\x1f\x7f-\x9f\u202e]/);
  assert.equal(Array.from(sanitizeText("😀".repeat(300))).length, 200);
  assert.equal(notificationSequence({}, hostile, hostile).split("\x07").length, 2);
});

test("arbitrary shell hook is ignored; bell requires explicit opt-in", () => {
  assert.equal(notificationSequence({ PI_NOTIFY_SOUND_CMD: "touch /tmp/never-run" }), notificationSequence({}));
  assert.equal(notificationSequence({ PI_NOTIFY_BELL: "1" }), notificationSequence({}) + "\x07");
});

// Exercise the real handler without emitting OSC sequences to the test terminal.
// Restore globals even on failure; tests in this file run sequentially.
async function captureSettlement(options = {}) {
  const { mode = "tui", env = {} } = options;
  const isTTY = Object.hasOwn(options, "isTTY") ? options.isTTY : true;
  const keys = ["TERM", "TERM_PROGRAM", "ITERM_SESSION_ID", "KITTY_WINDOW_ID",
    "TMUX", "PI_NOTIFY_DISABLED", "PI_NOTIFY_BELL", "PI_NOTIFY_SOUND_CMD"];
  const savedEnv = Object.fromEntries(keys.map((key) => [key, process.env[key]]));
  const ttyDescriptor = Object.getOwnPropertyDescriptor(process.stdout, "isTTY");
  const originalWrite = process.stdout.write;
  const writes = [];
  const handlers = new Map();
  try {
    for (const key of keys) delete process.env[key];
    Object.assign(process.env, env);
    Object.defineProperty(process.stdout, "isTTY", { configurable: true, value: isTTY });
    process.stdout.write = (chunk) => { writes.push(chunk); return true; };
    notify({ on: (name, handler) => handlers.set(name, handler) });
    await handlers.get("agent_settled")({}, { mode });
  } finally {
    process.stdout.write = originalWrite;
    if (ttyDescriptor) Object.defineProperty(process.stdout, "isTTY", ttyDescriptor);
    else delete process.stdout.isTTY;
    for (const key of keys) {
      if (savedEnv[key] === undefined) delete process.env[key];
      else process.env[key] = savedEnv[key];
    }
  }
  return { writes, events: [...handlers.keys()] };
}

test("registers only settlement and writes one notification in interactive mode", async () => {
  const { writes, events } = await captureSettlement();
  assert.deepEqual(events, ["agent_settled"]);
  assert.deepEqual(writes, [`${esc}]777;notify;Pi;Ready for input\x07`]);
});

for (const mode of ["rpc", "json", "print"]) {
  test(`does not write terminal escapes in ${mode} mode, even on a TTY`, async () => {
    assert.deepEqual((await captureSettlement({ mode })).writes, []);
  });
}

for (const isTTY of [false, undefined]) {
  test(`does not write when stdout.isTTY is ${isTTY}`, async () => {
    assert.deepEqual((await captureSettlement({ isTTY })).writes, []);
  });
}

test("TERM=dumb and explicit disable suppress both notification and bell", async () => {
  for (const env of [{ TERM: "dumb" }, { PI_NOTIFY_DISABLED: "1" }]) {
    assert.deepEqual((await captureSettlement({ env: { ...env, PI_NOTIFY_BELL: "1" } })).writes, []);
  }
});

test("handler respects terminal selection, passthrough, and optional bell", async () => {
  for (const env of [
    { TERM_PROGRAM: "iTerm.app", TMUX: "yes" },
    { KITTY_WINDOW_ID: "1", TMUX: "yes" },
    { PI_NOTIFY_BELL: "1" },
    { PI_NOTIFY_DISABLED: "0", PI_NOTIFY_SOUND_CMD: "never execute this" },
  ]) {
    assert.deepEqual((await captureSettlement({ env })).writes, [notificationSequence(env)]);
  }
});

test("sanitization removes all C0/C1 controls and bidi overrides", () => {
  const controls = Array.from({ length: 160 }, (_, n) => String.fromCharCode(n))
    .filter((char) => /[\x00-\x1f\x7f-\x9f]/.test(char)).join("");
  const bidi = "\u202a\u202b\u202c\u202d\u202e\u2066\u2067\u2068\u2069";
  assert.equal(sanitizeText(controls + bidi + ";"), " ".repeat(controls.length + bidi.length + 1));
  assert.equal(sanitizeText("Hello 世界 😀"), "Hello 世界 😀");
  assert.equal(sanitizeText(""), "");
  for (const env of [{}, { ITERM_SESSION_ID: "1" }, { KITTY_WINDOW_ID: "1" }]) {
    assert.equal(notificationSequence(env, "bad\x1b\x07;", "body\x9c\n"),
      notificationSequence(env, "bad   ", "body  "));
  }
});

test("Kitty takes precedence over inherited iTerm variables", () => {
  assert.equal(notificationSequence({ KITTY_WINDOW_ID: "1", TERM_PROGRAM: "iTerm.app" }),
    notificationSequence({ KITTY_WINDOW_ID: "1" }));
});

test("empty tmux and non-opt-in bell values leave output unchanged", () => {
  assert.equal(wrapForTmux("plain", false), "plain");
  for (const value of ["", "0", "true"]) {
    assert.equal(notificationSequence({ TMUX: "", PI_NOTIFY_BELL: value }), notificationSequence({}));
  }
});
