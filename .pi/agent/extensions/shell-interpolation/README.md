# Shell interpolation

User extension, automatically loaded from `~/.pi/agent/extensions/shell-interpolation/index.ts`.
Run `/reload` after installing or changing it.

Examples:

```text
/review
/review git diff main
Summarize this commit: !!(git show --stat)
```

For templates, Pi's discovered command list supplies the template path. The extension
strips frontmatter and substitutes template arguments **before** interpolating shell
commands. Templates with no shell markers stay on Pi's normal expansion path.
The review template uses `${@:-git show}` so missing arguments default to `git show`
and all supplied arguments form the replacement command.

Each `!!(command)` is replaced with stdout, with trailing newlines removed (spaces
are preserved). Commands run sequentially in the session working directory using
Pi's shell configuration. Output is not recursively interpolated. Attachments are
preserved. Extension-injected input is skipped.

Commands have a 30-second timeout. Nonzero exit, cancellation, malformed markers,
or stdout exceeding 1 MiB stops submission and reports an error. The output limit
is checked after execution, not a streaming memory limit. Successful stderr is
not inserted. Commands that already ran are not rolled back if a later one fails.

## Security and syntax

This executes arbitrary shell commands with Pi's permissions, **without an approval
dialog**. Only invoke trusted templates and input. Template arguments become shell
code, not automatically quoted data. Commands use `pi.exec`, not a model tool call,
so tool-call permission hooks do not apply. Output becomes model-visible prompt text.

The marker parser supports balanced parentheses, single/double/backtick quotes,
and backslash escapes. It is not a complete Bash parser: heredocs, shell comments
containing unmatched parentheses, and `case` patterns are not supported inside
markers. For complex shell programs, invoke a script instead. Markers are active
inside Markdown code fences too. Legacy WSL stdin-based shell transport is unsupported.

## Tests

From `~/.pi/agent`:

```sh
node --test extensionw/shell-interpolation/test/core.test.mjs
```
