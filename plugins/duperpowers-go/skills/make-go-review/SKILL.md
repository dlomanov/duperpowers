---
name: make-go-review
description: "Deep Go code review of current branch diff against origin/master (*.go files)"
disable-model-invocation: true
argument-hint: [additional context]
---

1. /duperpowers-go:go-reviewer make deep review of current branch diff against origin/master $ARGUMENTS
2. Write TL;DR — brief summary of what changed and why (3-5 sentences max)
3. /duperpowers:mit-writer full detailed explanation of all changes
