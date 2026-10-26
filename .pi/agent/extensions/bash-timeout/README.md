# Bash timeout

Forces every Pi `bash` tool call to use a **300-second (5-minute)** timeout,
including calls that supply a different timeout and nested calls from other tools.
Uses the `tool_call` hook, preserving the built-in Bash execution and rendering.
Other tools, user `!` commands, and extension `pi.exec()` calls are unaffected.

Load directly from this repository:

```sh
pi --extension ./.pi/agent/extensions/bash-timeout/index.ts
```

For automatic loading, install this directory at
`~/.pi/agent/extensions/bash-timeout`, then run `/reload` in an existing session.

## Tests

```sh
node --experimental-strip-types --test .pi/agent/extensions/bash-timeout/test/*.test.mjs
```
