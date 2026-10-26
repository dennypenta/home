import assert from "node:assert/strict";
import { test } from "node:test";
import { displayPath, parseNumstat } from "./core.ts";

test("sorts by added plus deleted lines and limits the view to the largest four", () => {
  const files = parseNumstat("1\t0\tsmall\0" + "10\t2\tlarge\0" + "3\t4\tmedium\0"
    + "0\t5\tdeleted\0" + "4\t0\tfifth\0");
  assert.equal(files.length, 5);
  assert.deepEqual(files.slice(0, 4).map((file) => file.path), ["large", "medium", "deleted", "fifth"]);
});

test("handles clean trees, binary files, and deterministic ties", () => {
  assert.deepEqual(parseNumstat(""), []);
  const files = parseNumstat("-\t-\timage.png\0" + "0\t0\ta\0");
  assert.equal(files[0].path, "a");
  assert.deepEqual(files[1], { path: "image.png", added: 0, deleted: 0, binary: true });
});

test("preserves unusual filenames and parses rename records", () => {
  const files = parseNumstat("2\t1\tfile\twith\ncontrols\0" + "1\t0\t\0old\0new\0");
  assert.equal(files[0].path, "file\twith\ncontrols");
  assert.equal(files[1].path, "old => new");
  assert.equal(displayPath(files[0].path), "file\\u0009with\\u000acontrols");
  assert.equal(displayPath("\x1b\x9b"), "\\u001b\\u009b");
});
