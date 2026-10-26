import assert from "node:assert/strict";
import { test } from "node:test";
import bashTimeout from "../index.ts";

function handler() {
  const handlers = new Map();
  bashTimeout({ on: (name, callback) => handlers.set(name, callback) });
  assert.deepEqual([...handlers.keys()], ["tool_call"]);
  return handlers.get("tool_call");
}

for (const timeout of [undefined, null, 0, 10, 300, 900]) {
  test(`forces a five-minute timeout when supplied timeout is ${timeout}`, () => {
    const input = { command: "echo hello" };
    if (timeout !== undefined) input.timeout = timeout;
    const event = { toolName: "bash", input };
    assert.equal(handler()(event), undefined);
    assert.deepEqual(input, { command: "echo hello", timeout: 300 });
  });
}

test("does not modify other tools", () => {
  const input = { command: "example", timeout: 10 };
  handler()({ toolName: "other", input });
  assert.deepEqual(input, { command: "example", timeout: 10 });
});

test("also applies to nested bash calls", () => {
  const event = {
    toolName: "bash",
    toolCallId: "parent/1",
    parentToolCallId: "parent",
    input: { command: "echo nested" },
  };
  handler()(event);
  assert.equal(event.input.timeout, 300);
});
