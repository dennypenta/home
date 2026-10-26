import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdtemp, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import { collectStats } from "./core.ts";

test("includes untracked text, empty and binary files, ignores ignored files, and refreshes counts", async () => {
  const cwd = await mkdtemp(join(tmpdir(), "pi-diff-stat-"));
  const git = (args: string[]) => new Promise<{ code: number; stdout: string }>((resolve, reject) => {
    execFile("git", args, { cwd }, (error, stdout) => {
      if (error && typeof error.code !== "number") reject(error);
      else resolve({ code: error ? Number(error.code) : 0, stdout });
    });
  });
  try {
    await git(["init", "-q"]);
    await writeFile(join(cwd, ".gitignore"), "ignored\n");
    await writeFile(join(cwd, "tracked"), "before\n");
    await git(["add", "."]);
    await writeFile(join(cwd, "tracked"), "after\nextra\n");
    await writeFile(join(cwd, "new\tfile"), "one\ntwo\nthree");
    await writeFile(join(cwd, "empty"), "");
    await writeFile(join(cwd, "binary"), Buffer.from([0, 1, 2]));
    await writeFile(join(cwd, "ignored"), "not displayed\n");
    const files = await collectStats(git);
    assert.equal(files.length, 4);
    assert.deepEqual(files.find((file) => file.path === "new\tfile"), {
      path: "new\tfile", added: 3, deleted: 0, binary: false,
    });
    assert.equal(files.find((file) => file.path === "binary")?.binary, true);
    assert.equal(files.find((file) => file.path === "empty")?.added, 0);
    assert.equal(files.find((file) => file.path === "tracked")?.deleted, 1);
    await writeFile(join(cwd, "new\tfile"), "one\n");
    assert.equal((await collectStats(git)).find((file) => file.path === "new\tfile")?.added, 1);
  } finally {
    await rm(cwd, { recursive: true, force: true });
  }
});
