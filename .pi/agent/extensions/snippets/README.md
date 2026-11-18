## Use

The snippet picker opens automatically at interactive session startup (including `/new`, `/resume`, and `/reload`). Non-interactive runs do not open it. Reopen it with `/snippets` or `Alt+S`. Arrows navigate, Space selects, Tab previews, Enter applies. Then send your task normally. Selecting several snippets combines their instructions in menu order: `prepend` snippets go before your text, and `append` snippets go after it. The widget near the editor shows which snippets are armed for the next message.

For example, select **Short** and **Schematic**, press Enter, then send `Explain the login flow`. The model receives:

```text
Explain the login flow

Be short and concise.

Prefer visual markdown schemas in explanation of data flows and execution orders.
```

There is no inline activation syntax: typing a snippet name in a prompt does not activate it. Use the menu before sending. After changing extension code, run `/reload` first.

Selections reset after each message and at session start. This is prompt guidance, not a runtime permission gate.

The menu is the only entry point. Snippet bodies live in exactly one place, so there are no `/delegate-work` or `/workflow` shortcuts to drift from them.

## Maintenance

Names, descriptions, and prompts are English. Response language follows the user.

Snippet definitions are Markdown files under `snippets/`. The menu is flat, sorted by placement (`prepend` first), numeric `order`, then name. Categories are not supported; any old `category` fields are ignored. Edits load when the menu reopens and before selected snippets are inserted; extension code changes require `/reload`.

```markdown
---
name: Short
description: Be short and concise.
placement: append
order: 1
---

Be short and concise.
```

Frontmatter and a nonempty body are required. `name` defaults to the filename without `.md`, `description` to empty, `order` to 9999, and `placement` to `prepend`.

Keep outcome, completion criteria, and user-specific constraints in snippets; leave task-specific methods to the agent and consult skills for the guidance the task needs. Delegate and Workflow explicitly select async execution. Clarify ends when the decisions needed for the next step are resolved. Handoff targets the next session's focus and links existing artifacts. The snippet bodies are authoritative for execution details. Model, context and concurrency defaults belong in settings.

The published package contains only the extension, its bundled snippets, documentation, and license. It performs no network requests or subprocess execution.

