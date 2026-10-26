# Git diff stat widget

Displays unstaged tracked changes plus untracked, non-ignored files above Pi's editor. New files are counted as additions, including empty and binary files. Staged changes remain excluded.

- Shows at most **4 files**, sorted by **added + deleted lines**, descending; ties sort by path.
- Each row shows total changed lines, green additions, red deletions, and the filename. Binary files are labeled `binary` and rank as zero lines.
- The heading reports the total file count and how many files are hidden.
- Refreshes every two seconds and after tool execution / agent completion, including changes made outside Pi.
- Hidden for clean trees, outside Git repositories, and in non-TUI modes.
- Polling and in-flight Git commands are stopped on session shutdown or `/reload`.

This directory is auto-loaded via `~/.pi/agent/extensions` (linked to this repository). Run `/reload` in an existing Pi session to load it.

Tests:

```sh
node --test .pi/agent/extensions/git-diff-stat/*.test.ts
```
