import assert from "node:assert/strict";
import { test } from "node:test";
import footerInterpolation, { parseFooter } from "../index.ts";

const model = { provider: "openai", id: "gpt-tera-6" };

function setup({ models = [model], availableModels = models, setModel = async () => true } = {}) {
  let handler;
  const switches = [];
  const errors = [];
  footerInterpolation({
    on(name, callback) {
      assert.equal(name, "input");
      handler = callback;
    },
    async setModel(value) {
      switches.push(value);
      return setModel(value);
    },
  });
  const ctx = {
    hasUI: true,
    modelRegistry: { getAll: () => models, getAvailable: () => availableModels },
    ui: { notify: (message, level) => errors.push({ message, level }) },
  };
  return {
    run: (text, extra = {}) => handler({ text, source: "interactive", ...extra }, ctx),
    switches,
    errors,
  };
}

for (const suffix of ["", "\n", "\n\n", "  \n \n"]) {
  test(`strips a trailing footer with suffix ${JSON.stringify(suffix)}`, async () => {
    const app = setup();
    assert.deepEqual(await app.run(`do something\n\n#model gpt-tera-6${suffix}`), {
      action: "transform", text: "do something", images: undefined,
    });
    assert.deepEqual(app.switches, [model]);
    assert.deepEqual(app.errors, []);
  });
}

test("resolves the reported prompt against available models, ignoring unavailable duplicates", async () => {
  const luna = { provider: "configured", id: "gpt-6-luna" };
  const unavailable = { provider: "unconfigured", id: "gpt-6-luna" };
  const app = setup({ models: [unavailable, luna], availableModels: [luna] });
  const body = "how to name @src/store/query/QueryHits.zig ?\n@src/store/query/BlockQuery.zig";
  assert.deepEqual(await app.run(`${body}\n\n#model gpt-6-luna`), {
    action: "transform", text: body, images: undefined,
  });
  assert.deepEqual(app.switches, [luna]);
  assert.deepEqual(app.errors, []);
});

test("handles CRLF and preserves whitespace within the body", () => {
  assert.deepEqual(parseFooter("  do\r\n\r\nsomething\r\n\r\n#model gpt-tera-6\r\n"), {
    text: "  do\r\n\r\nsomething", model: "gpt-tera-6",
  });
});

for (const text of [
  "do something", "do #model gpt-tera-6", "#model gpt-tera-6\nthen do something",
  "#other value", "```text\n#model gpt-tera-6", "~~~\n#model gpt-tera-6",
  "```\n#model gpt-tera-6\n```", "", "\n",
]) {
  test(`leaves non-footer content untouched: ${JSON.stringify(text)}`, async () => {
    const app = setup();
    assert.deepEqual(await app.run(text), { action: "continue" });
    assert.deepEqual(app.switches, []);
  });
}

test("recognizes a footer following a closed fence", () => {
  assert.deepEqual(parseFooter("```\nexample\n```\n\n#model gpt-tera-6"), {
    text: "```\nexample\n```", model: "gpt-tera-6",
  });
});

test("accepts provider-qualified IDs and IDs containing slashes", async () => {
  const other = { provider: "other", id: model.id };
  const slash = { provider: "host", id: "org/model" };
  const app = setup({ models: [model, other, slash] });
  assert.equal((await app.run("do something\n#model other/gpt-tera-6")).action, "transform");
  assert.equal((await app.run("do something\n#model org/model")).action, "transform");
  assert.deepEqual(app.switches, [other, slash]);
});

test("waits for the model switch before returning the prompt", async () => {
  let release;
  let finished = false;
  const app = setup({ setModel: () => new Promise((resolve) => { release = resolve; }) });
  const pending = app.run("do something\n#model gpt-tera-6").then((result) => {
    finished = true;
    return result;
  });
  await Promise.resolve();
  assert.equal(finished, false);
  release(true);
  assert.equal((await pending).action, "transform");
});

test("preserves images and supports RPC input", async () => {
  const app = setup();
  const images = [{ type: "image", data: "image-data", mimeType: "image/png" }];
  assert.deepEqual(await app.run("describe\n#model gpt-tera-6", { source: "rpc", images }), {
    action: "transform", text: "describe", images,
  });
});

test("ignores extension-injected input", async () => {
  const app = setup();
  assert.deepEqual(await app.run("do something\n#model gpt-tera-6", { source: "extension" }), { action: "continue" });
  assert.deepEqual(app.switches, []);
});

test("a standalone directive switches without starting a prompt", async () => {
  const app = setup();
  assert.deepEqual(await app.run("#model gpt-tera-6"), { action: "handled" });
  assert.deepEqual(app.switches, [model]);
});

for (const value of ["", "gpt-tera-6 extra", "not-a-model"]) {
  test(`blocks invalid directives: ${JSON.stringify(value)}`, async () => {
    const app = setup();
    assert.deepEqual(await app.run(`do something\n#model ${value}`), { action: "handled" });
    assert.deepEqual(app.switches, []);
    assert.equal(app.errors[0].level, "error");
  });
}

test("blocks ambiguous model IDs", async () => {
  const app = setup({ models: [model, { ...model, provider: "other" }] });
  assert.deepEqual(await app.run("do something\n#model gpt-tera-6"), { action: "handled" });
  assert.match(app.errors[0].message, /Ambiguous model.*openai\/gpt-tera-6.*other\/gpt-tera-6/);
  assert.deepEqual(app.switches, []);
});

for (const setModel of [async () => false, async () => { throw new Error("switch failed"); }]) {
  test("blocks submission when switching fails", async () => {
    const app = setup({ setModel });
    assert.deepEqual(await app.run("do something\n#model gpt-tera-6"), { action: "handled" });
    assert.equal(app.errors[0].level, "error");
  });
}
