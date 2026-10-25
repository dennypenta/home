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

test("Kitty uses two parts with callbacks disabled", () => {
  assert.equal(notificationSequence({ KITTY_WINDOW_ID: "1" }),
    `${esc}]99;i=pi-complete:d=0:a=0;Pi${st}`
    + `${esc}]99;i=pi-complete:p=body:d=1:a=0;Ready for input${st}`);
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

test("registers only final settlement; skips all non-TUI modes", async () => {
  const handlers = new Map();
  notify({ on: (name, handler) => handlers.set(name, handler) });
  assert.deepEqual([...handlers.keys()], ["agent_settled"]);
  // These must return before accessing terminal output or environment settings.
  for (const mode of ["rpc", "json", "print"]) {
    await handlers.get("agent_settled")({}, { mode });
  }
});
