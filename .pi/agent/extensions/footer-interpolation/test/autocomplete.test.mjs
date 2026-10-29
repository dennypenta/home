import assert from "node:assert/strict";
import { test } from "node:test";
import footerInterpolation, { createModelAutocompleteProvider } from "../index.ts";

const models = [
  { provider: "openai", id: "gpt-tera-6" },
  { provider: "other", id: "gpt-tera-6" },
  { provider: "host", id: "org/model" },
];
const options = { signal: new AbortController().signal };

function setup() {
  const calls = [];
  const fallback = {
    triggerCharacters: ["@"],
    async getSuggestions(...args) { calls.push(args); return null; },
    applyCompletion(...args) { calls.push(args); return "fallback"; },
    shouldTriggerFileCompletion() { return false; },
  };
  return { provider: createModelAutocompleteProvider(fallback, () => models), calls };
}

test("lists provider-qualified models on an empty directive", async () => {
  const { provider } = setup();
  const result = await provider.getSuggestions(["prompt", "#model "], 1, 7, options);
  assert.equal(result.prefix, "");
  assert.deepEqual(result.items.map((item) => item.value), [
    "host/org/model", "openai/gpt-tera-6", "other/gpt-tera-6",
  ]);
});

for (const [query, expected] of [
  ["GPT", ["openai/gpt-tera-6", "other/gpt-tera-6"]],
  ["other/gpt", ["other/gpt-tera-6"]],
  ["org/", ["host/org/model"]],
]) {
  test(`filters models using ${query}`, async () => {
    const { provider } = setup();
    const line = `#model ${query}`;
    const result = await provider.getSuggestions([line], 0, line.length, options);
    assert.equal(result.prefix, query);
    assert.deepEqual(result.items.map((item) => item.value), expected);
  });
}

test("does not fall back to file completion for an unknown model", async () => {
  const { provider, calls } = setup();
  assert.equal(await provider.getSuggestions(["#model missing"], 0, 14, options), null);
  assert.deepEqual(calls, []);
});

for (const line of ["hello", "text #model gpt", " #model gpt", "#models gpt", "#model gpt extra"]) {
  test(`delegates completion outside a directive: ${line}`, async () => {
    const { provider, calls } = setup();
    await provider.getSuggestions([line], 0, line.length, options);
    assert.equal(calls.length, 1);
    assert.equal(provider.applyCompletion([line], 0, line.length, { value: "x" }, ""), "fallback");
    assert.deepEqual(provider.triggerCharacters, ["@"]);
    assert.equal(provider.shouldTriggerFileCompletion([line], 0, line.length), false);
  });
}

test("replaces a model token without changing the prompt or trailing whitespace", () => {
  const { provider } = setup();
  const lines = ["do something", "#model gp-old  ", ""];
  const result = provider.applyCompletion(lines, 1, 9, { value: "other/gpt-tera-6" }, "gp");
  assert.deepEqual(result, {
    lines: ["do something", "#model other/gpt-tera-6  ", ""],
    cursorLine: 1,
    cursorCol: 23,
  });
  assert.equal(lines[1], "#model gp-old  ");
});

test("registers only in TUI mode and reads the live available-model list", async () => {
  const handlers = {};
  footerInterpolation({ on(name, handler) { handlers[name] = handler; } });
  let factory;
  let available = [models[0]];
  const ctx = {
    mode: "rpc",
    modelRegistry: { getAvailable: () => available },
    ui: { addAutocompleteProvider(value) { factory = value; } },
  };
  handlers.session_start({}, ctx);
  assert.equal(factory, undefined);
  ctx.mode = "tui";
  handlers.session_start({}, ctx);
  const provider = factory({});
  assert.equal((await provider.getSuggestions(["#model "], 0, 7, options)).items.length, 1);
  available = models;
  assert.equal((await provider.getSuggestions(["#model "], 0, 7, options)).items.length, 3);
});
