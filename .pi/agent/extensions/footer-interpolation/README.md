# Footer interpolation

Pi extension that reads a model directive from the last nonblank line of user input.
Reload Pi with `/reload` after installation.

```text
do something

#model gpt-tera-6
```

The extension awaits the switch to `gpt-tera-6`, then submits only `do something`.
The model must exist in Pi's model registry and have working credentials; this
extension does not register new models. The selected model stays active for
subsequent prompts, just like a normal model switch.

Model lookup uses Pi's available-model list, ignoring providers without credentials.
Use a provider-qualified name when multiple available providers offer the same model ID:

```text
do something

#model openai/gpt-tera-6
```

## Autocomplete

In the interactive editor, start a line with `#model ` and press **Tab** to
suggest available models. Type part of a model ID or `provider/model-id` to
filter the list (case-insensitive). Completions insert provider-qualified IDs
so models offered by multiple providers are unambiguous. The list uses the
same credential-filtered registry as model switching; other editor completions
remain unchanged.

## Behavior

- Supports `#model <model-id>` and `#model <provider/model-id>` (exact matches).
- The directive must start at the beginning of the last nonblank line. A final
  newline is optional; trailing blank lines and CRLF input are supported.
- Removes the directive and trailing whitespace from the prompt body, preserving
  other content and image attachments.
- A standalone `#model` directive with a valid value switches without starting an
  empty prompt. Image-only prompts still run.
- Unknown/ambiguous models, malformed directives, and failed switches report an
  error and stop submission rather than silently using the previous model.
- Directives inside backtick/tilde fenced code blocks are left untouched.
- Supports interactive and RPC input; ignores extension-injected messages.
- Only `#model` is interpreted; other hashtags remain prompt content.

This uses the `input` hook, before normal prompt-template/skill expansion. Put the
footer in submitted input, not inside a template body. It changes the active
session model immediately, including when submitting steering/follow-up input
while Pi is busy; it is not a per-queued-message model override.

## Tests

From the repository root (Node.js with TypeScript type stripping):

```sh
node --test .pi/agent/extensions/footer-interpolation/test/*.test.mjs
```
