import assert from "node:assert/strict";
import { test } from "node:test";
import { execFileSync } from "node:child_process";
import { readFile } from "node:fs/promises";
import { interpolate, parseArgs, parseInterpolations, substituteArgs } from "../core.mjs";

const execute = async (command) => execFileSync("/bin/bash", ["-c", command], { encoding: "utf8" });

test("review defaults and multiword override expand before shell markers", async () => {
  const template = await readFile(new URL("../../../prompts/review.md", import.meta.url), "utf8");
  const body = template.replace(/^---\n[\s\S]*?\n---\n/, "");
  for (const [args, command] of [["", "git show"], ["git diff main", "git diff main"], ['"git diff main"', "git diff main"]]) {
    const expanded = substituteArgs(body, parseArgs(args));
    assert.ok(expanded.startsWith(`Review the patch !!(${command}).`));
    const calls = [];
    const result = await interpolate(expanded, async (cmd) => { calls.push(cmd); return "PATCH\n"; });
    assert.deepEqual(calls, [command]);
    assert.ok(result.startsWith("Review the patch PATCH."));
  }
});

test("Pi argument syntax remains compatible and nonrecursive", () => {
  assert.deepEqual(parseArgs('one "two three" \'\' four'), ["one", "two three", "", "four"]);
  assert.equal(substituteArgs('$1|$2|${3:-default}|$@|${@:2:1}|${ARGUMENTS:-none}', ["$2", "x"]), "$2|x|default|$2 x|x|$2 x");
});

test("real shell output, multiple markers, quotes and nested parentheses", async () => {
  assert.equal(await interpolate('A !!(printf "a)b") B !!(printf "%s" "$(printf nested)") C !!((printf sub))', execute), "A a)b B nested C sub");
  assert.equal(await interpolate("!!(printf '%s' '!!(no recursion)')", execute), "!!(no recursion)");
  assert.equal(await interpolate("!!(printf '  content  \\n\\n')", execute), "  content  ");
  assert.equal(await interpolate("plain text", execute), "plain text");
});

test("invalid input is rejected before executing any command", async () => {
  let calls = 0;
  await assert.rejects(interpolate("!!(echo first) !!(unclosed", async () => { calls++; return ""; }), /Unclosed/);
  assert.equal(calls, 0);
  assert.throws(() => parseInterpolations("!!( )"), /Empty/);
  assert.throws(() => parseInterpolations('!!(echo "oops)'), /Unclosed/);
});

test("execution failures propagate and stop subsequent commands", async () => {
  const calls = [];
  await assert.rejects(interpolate("!!(first) !!(second)", async (command) => {
    calls.push(command);
    throw new Error("exit 1");
  }), /exit 1/);
  assert.deepEqual(calls, ["first"]);
});
