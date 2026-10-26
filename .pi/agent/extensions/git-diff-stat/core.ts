export interface FileStat {
  path: string;
  added: number;
  deleted: number;
  binary: boolean;
}

/** Parse Git's NUL-delimited numstat, including its three-field rename form. */
export function parseNumstat(output: string): FileStat[] {
  const fields = output.split("\0");
  const files: FileStat[] = [];
  for (let i = 0; i < fields.length; i++) {
    const match = /^(\d+|-)\t(\d+|-)\t([\s\S]*)$/.exec(fields[i]);
    if (!match) continue;
    let path = match[3];
    if (!path) {
      const from = fields[++i];
      const to = fields[++i];
      if (from === undefined || to === undefined) continue;
      path = `${from} => ${to}`;
    }
    files.push({
      path,
      added: match[1] === "-" ? 0 : Number(match[1]),
      deleted: match[2] === "-" ? 0 : Number(match[2]),
      binary: match[1] === "-" || match[2] === "-",
    });
  }
  return files.sort((a, b) =>
    (b.added + b.deleted) - (a.added + a.deleted) || a.path.localeCompare(b.path),
  );
}

type GitResult = { code: number; stdout: string };
type RunGit = (args: string[]) => Promise<GitResult>;

/** Run from the repository root so tracked and untracked paths agree. */
export async function collectStats(runGit: RunGit): Promise<FileStat[]> {
  const [diff, untracked] = await Promise.all([
    runGit(["diff", "--no-ext-diff", "--no-textconv", "--numstat", "-z", "--"]),
    runGit(["ls-files", "--others", "--exclude-standard", "-z"]),
  ]);
  if (diff.code !== 0 || untracked.code !== 0) throw new Error("Cannot read Git changes");
  const files = parseNumstat(diff.stdout);
  for (const path of untracked.stdout.split("\0").filter(Boolean)) {
    const result = await runGit([
      "diff", "--no-index", "--no-ext-diff", "--no-textconv", "--numstat", "-z", "--", "/dev/null", path,
    ]);
    // --no-index exits 1 when differences exist, including newly created files.
    // A file removed while polling is simply omitted until the next refresh.
    if (result.code !== 0 && result.code !== 1) continue;
    const stat = parseNumstat(result.stdout)[0];
    files.push(stat ? { ...stat, path } : { path, added: 0, deleted: 0, binary: false });
  }
  return files.sort((a, b) =>
    (b.added + b.deleted) - (a.added + a.deleted) || a.path.localeCompare(b.path),
  );
}

export function displayPath(path: string): string {
  // Do not allow filenames to inject terminal controls or extra widget lines.
  return path.replace(/[\x00-\x1f\x7f-\x9f\u2028\u2029]/g,
    (char) => `\\u${char.charCodeAt(0).toString(16).padStart(4, "0")}`,
  );
}
