# Completion notifications

Notifies with **Pi — Ready for input** when `agent_settled` fires, after retries,
compaction, and queued work stop. This means Pi is idle, not that the task
necessarily succeeded; errors and cancellation may also lead to settlement.

## Load

Pi auto-discovers `notify/index.ts` when this directory is in the active agent
extension directory. Run `/reload` in an existing session. Alternatively:

```sh
pi --extension /absolute/path/to/extensions/notify/index.ts
```

Requires a Pi version with `agent_settled` and `ctx.mode` (developed against 1.4.0).

## Terminals

- Ghostty, WezTerm, rxvt-unicode: OSC 777 (default).
- iTerm2: OSC 9.
- Kitty: OSC 99, with activation callbacks disabled.
- tmux: DCS passthrough wrapping with inner ESC bytes doubled. Your tmux
  configuration must allow passthrough; this extension does not change it.

Enable notifications in your terminal and OS settings. Unsupported terminals
may silently ignore the sequences. Detection under tmux/SSH depends on forwarded
terminal environment variables. This extension neither probes terminal support
nor changes terminal permissions.

Windows PowerShell toasts are deliberately omitted: Windows Terminal gets the
terminal protocol fallback, which may not display notifications. No native
Windows toast support is claimed.

## Options

Set these in the environment **before starting Pi**:

- `PI_NOTIFY_DISABLED=1`: disable notifications.
- `PI_NOTIFY_BELL=1`: append a terminal bell; actual sound depends on terminal settings.

`PI_NOTIFY_SOUND_CMD` from the supplied sample is intentionally **not supported**.

## Security decisions

- No subprocesses, shell commands, PowerShell, dependencies, network requests,
  filesystem reads/writes, or access to conversation/session content.
- Only fixed generic text is emitted, avoiding private task details in desktop
  notifications. Text helpers also strip control characters, semicolons, and
  bidi overrides and limit each field to 200 Unicode code points.
- No terminal output in RPC/JSON/print modes, redirected stdout, or `TERM=dumb`.
- No terminal callbacks or automatic tmux/OS configuration changes.

The original sample's shell sound hook can execute arbitrary code from an
environment variable. Its PowerShell string interpolation and raw OSC fields
would also be injection risks if their fixed messages were replaced with
untrusted text. Those execution paths are removed here.

Extensions still run with Pi's full process permissions, and terminal rendering
is handled by your terminal emulator. These precautions reduce risk; they are
not a sandbox or a guarantee against terminal-emulator vulnerabilities.

## Tests

On Node.js with native TypeScript stripping (Node 22.18+):

```sh
node --test extensions/notify/test/notify.test.mjs
```
