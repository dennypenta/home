# Plan mode

Run `/plan <request>` to investigate a task without giving the model editing or shell tools:

```text
/plan add caching to the project lookup API
```

The assistant explores with `read`, `grep`, `find`, and `ls`, then returns a self-contained Markdown implementation plan. The extension saves the final response in the current project's `.pi/plans/<UTC-timestamp>.md` and displays it before offering:

1. **Accept and execute in this session** — restores the prior tools, enables `edit`, `write`, and `bash`, and submits the accepted plan for implementation.
2. **Accept and execute in a new session** — creates a session linked to the current one, enables execution tools, and submits the full plan as its first user prompt. No previous conversation is copied.
3. **Keep the plan without executing** — leaves the file in place and restores the previous tools. Dismissing the selector does the same.

The third option is the non-executing path added because the request listed only two of the three desired options.

## Safety and behavior

- Planning must start while the agent is idle with no queued messages.
- A tool-call guard blocks all tools outside the four-tool allowlist, including shell tools, custom tools, and nested calls.
- No shell-command heuristics or unverified MCP read-only annotations are used.
- The extension, not the model, writes the plan file. Timestamp collisions use a numeric suffix rather than overwriting a file.
- Aborted, failed, and empty responses are not saved or executed. Save failures never lead to execution.
- The planning restriction remains active through saving and selection; normal tools return after completion or cancellation.
- In print/JSON mode the plan is saved and displayed, but never automatically executed. TUI and RPC clients can select an action.
- This is a tool-level workflow restriction, not an operating-system sandbox. Other extensions execute with Pi's normal process permissions. Do not load untrusted extensions or override the allowlisted tools with mutating implementations.

## Installation

This directory is auto-discovered under `~/.pi/agent/extensions/` through this repository's `setup.sh`. Run `/reload` in Pi after installing. Do not also load Pi's example `plan-mode` extension: both register `/plan`.

Plan files are relative to the active project's working directory, not this extension directory. Add `.pi/plans/` to the project's ignore rules if plans should stay local.

## Tests

With Node.js supporting native TypeScript stripping (Node 22.18+):

```sh
node --test .pi/agent/extensions/plan-mode/plan-mode.test.ts
```

The tests use a simulated extension API and do not call a model provider.
