# Duperpowers — Personal Preferences

This is the author's personal preferences template. Review and adapt to your own workflow before adding to `~/.claude/CLAUDE.md`. The plugin works without any of this — it's entirely optional.

---

## Duperpowers — Personal Preferences

<CRITICAL>
Never add `Co-Authored-By: Claude*` or any AI attribution to commit messages. Never.
Never use `/tmp`, `/private/tmp`, or any system temp directories. Use `~/src/sand/docs/`.
If `~/src/sand/docs/` does not exist, create it with `mkdir -p ~/src/sand/docs/`.
Prefer pipelines over temp files.
Always run `make *`, `go get *`, `go mod *` with unset proxy: `HTTP_PROXY= HTTPS_PROXY= http_proxy= https_proxy= no_proxy= NO_PROXY=`.
After code review: fix all CRIT and ERR findings yourself, then re-run review. Only report WARN/INFO to user.
</CRITICAL>

## Duperpowers — INVARIANTS

<CRITICAL>
**Final opus review is MANDATORY.** After ALL implementation tasks complete in subagent-driven-development, ALWAYS dispatch a final code reviewer with `model: opus`. Fix every finding opus reports. Re-run opus review after fixes. Repeat until opus gives clean PASS (max 2 fix-review cycles). gocheck (build/test/vet) is verification, NOT a substitute for final review. When writing a plan, ALWAYS include an explicit "Final opus review" step in the plan. No implicit steps — if it's not in the plan, it won't happen.

| Rationalization | Reality |
|---|---|
| "gocheck passed, we're done" | gocheck checks compilation. Opus checks correctness, edge cases, style. Different gates. |
| "Per-task reviews already covered this" | Per-task reviews are scoped to one task. Final review checks cross-task integration and full picture. |
| "The plan is simple, no review needed" | Every plan gets final opus review. No exceptions. Simple plans = fast review. |
| "I'll save tokens by skipping" | Skipping costs MORE when bugs ship. ALWAYS run it. |
</CRITICAL>

- **Validate before proposing:** Score each suggestion 1-100 internally. Only propose 95+. If you can disprove your own suggestion — do that analysis first, discard the suggestion. When uncertain — always say "I'm not sure" upfront.
- **Always leave code working:** A task is incomplete until build and tests pass. If your changes break anything — fixing it is part of your task.
- **Review tags:** Lines containing `@review ...` are user review comments. In non-SQL files `-- ...` is also a review tag. Consecutive review tag lines form one multiline comment. Fix or discuss the issue, then delete the tag lines after resolution.
- **Addressable responses:** When answering multiple topics/decisions, number each with a short ID (T1, T2, ...). User can batch-reply by ID.
- **Challenge before executing:** If a user request contradicts loaded skills, established rules, or logical consistency — challenge with evidence before executing. Do NOT silently comply. User can override with explicit push.
- **FATAL: `dial tcp` in make commands.** `dial tcp: lookup ... no such host` = network is down. STOP. Do not debug. Do not run `go env`. Do not retry. Report: `BLOCKED: network down (dial tcp). Waiting.` All agents in chain STOP and propagate BLOCKED.

## Duperpowers — PROTOCOLS

- **Comments:** DO NOT write comments that don't answer WHY. If a comment would restate what the code does, omit it.
- **Russian text:** Always replace Ё/ё with Е/е (never use Ё/ё). Always use minus-hyphen (-) for dashes, never en dash (–) or em dash (—).
- **Never commit:** Always skip when staging: CLAUDE.md, .claude/*, task*.md, plans/*
