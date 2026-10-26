---
allowed-tools: Bash(git diff:*), Bash(git status:*), Bash(git log:*)
argument-hint: "[command, docs]"
description: Document a git diff
---

Current git diff: !!(${1:-git show})

Document the change in $2


