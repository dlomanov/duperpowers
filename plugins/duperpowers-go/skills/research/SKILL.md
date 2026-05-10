---
name: research
description: "Use when investigating an unfamiliar codebase area, system, or topic that needs exploring along multiple angles before decisions or changes. Triggers: user asks for research / deep-dive / system-mapping / understand-how-X-works."
---

# Research

<IMPORTANT>

## Golden Rules

- **RS-1.** Derive 2-5 dimensions for the topic. Present them to the user. Wait for OK before dispatching subagents.
- **RS-2.** Dispatch one subagent per dimension, in parallel. Each brief is self-contained — subagent has zero main-session context.
- **RS-3.** Files live in `~/src/sand/docs/research/{topic-slug}/`. Per-dimension `*.md` + `REPORT.md`. Override only on explicit user request.
- **RS-4.** Challenge every subagent output before consolidating. Spot-check 1-2 file:line refs per file. Re-dispatch on hallucination, gap, or contradiction. Pass nothing through unverified.
- **RS-5.** Final deliverable is `REPORT.md`. Standalone — output is for the user, not input to another skill.
- **RS-6.** Never paste subagent transcripts into chat. Read files, consolidate, summarise.
- **RS-7.** Subagent fails after 2 dispatch attempts → mark dimension UNRESOLVED in `REPORT.md` with diagnosis. Continue rest. Surface to user.

## Anti-patterns

| Rationalization | Reality |
|----------------|---------|
| "I'll skip user-OK on dimensions, dispatch immediately" | Wrong dimensions waste 5x tokens. 30 seconds of confirm beats one bad parallel run. |
| "One dimension is enough" | Single-axis exploration misses cross-cutting facts. Use ≥2 dimensions or skip the skill. |
| "Subagent output looks fine, no need to challenge" | Subagents hallucinate file:line refs. Spot-check is mandatory (RS-4). |
| "I'll paste raw subagent files into chat" | Transcripts are noisy and burn tokens. Consolidate to `REPORT.md` (RS-6). |
| "Save findings into the repo `docs/`" | Default is `~/src/sand/docs/research/`. User copies into repo if they want it tracked. |
| "Research feeds the planner — chain it next" | No (RS-5). Standalone. The user reads the report, then decides. |
| "More dimensions = more thorough" | >5 = redundant work and slower consolidation. 2-5 is the band. |

</IMPORTANT>

## Dimensions

A dimension is an angle that can be investigated independently from the others. Pick disjoint dimensions — overlap = redundant work.

Common dimensions (pick what fits the topic, not all):

| Dimension | Covers | Tools |
|-----------|--------|-------|
| **Code** | Types, interfaces, call graph, file:line | Grep, Read, AST |
| **Architecture** | Layers, abstractions, patterns | Read |
| **History** | Why was it built this way? Major refactors | `git log`, `git blame` |
| **Tests** | Coverage, patterns, gaps | Read |
| **Constraints** | Performance, breaking-change risk, cross-package deps | Grep + Read |
| **External** | APIs, configs, third-party integrations | Read + WebFetch |
| **Domain** | Business rules, terminology, edge cases | Read + user interview |

## Process

1. Clarify the topic — one-sentence statement of what the user wants to know.
2. Derive 2-5 dimensions. Present to user. Wait for OK.
3. Slug the topic: kebab-case, ≤30 chars (`billing-postprocessing`, `event-bus`, `auth-chain`).
4. Draft a brief per dimension — use the template below.
5. Dispatch in parallel via Agent tool, `run_in_background: true`. Model = opus for ambiguous dimensions, sonnet for mechanical.
6. As each subagent lands: challenge per RS-4.
7. Consolidate into `REPORT.md`.
8. Tell user: research at `<path>`. Per-dimension files alongside if depth needed.

## Subagent brief template

Each brief is a complete prompt. The subagent sees nothing else.

```
Goal: <one sentence — the dimension question>

Topic: <user's topic in one sentence>

Dimension scope (in / out):
- IN: <what this dimension covers>
- OUT: <what's covered by other dimensions>

Files to start with: <2-5 paths if known>

Output:
- Write to `~/src/sand/docs/research/{topic-slug}/{dimension}.md`
- Format: ## Scope → ## Findings (bullets with file:line) → ## Constraints → ## Implications → ## Open questions

Discipline:
- Cite ≥10 file:line refs (target; lower if dimension is small).
- Do NOT speculate beyond the codebase. Mark unknowns as "UNKNOWN: <what>".
- When done, output a 3-line summary in chat.

Tools allowed: Read, Grep, Bash (git log / find / rg). [+ WebFetch / WebSearch only for History or External.]
```

Keep briefs ≤80 lines. Self-contained.

## Challenge phase (RS-4)

For each landed subagent file, do this checklist before accepting:

1. **Spot-check refs.** Pick 1-2 file:line refs at random. Open and verify. Wrong → re-dispatch with corrective brief.
2. **Unsupported claims.** Any fact stated without a ref? Flag.
3. **Cross-check.** Same fact stated differently across two dimensions? One is wrong (or terminology drift). Resolve.
4. **Gap scan.** Did the dimension miss something obvious in its own scope? E.g., "tests" dimension didn't mention integration tests when they clearly exist. Re-dispatch.
5. **Decision:** PASS / RE-DISPATCH (sharper brief) / ESCALATE (user resolves).

Budget: 2 dispatches per dimension. After that → UNRESOLVED in `REPORT.md`.

## REPORT.md format

```markdown
# Research — <topic>

**Scope:** <one sentence>
**Dimensions:** code, tests, constraints
**Status:** complete | UNRESOLVED: <dimensions>

## Executive summary

<3-5 sentences. The thing the user walks away with.>

## By dimension

### Code
<1-3 paragraphs distilled from `code.md`. The "what reviewers must remember" version.>

### Tests
<...>

### Constraints
<...>

## Cross-cutting observations

<Things visible only when dimensions are read together. Often the highest-value section.>

## Open questions

<What couldn't be resolved. Why. Pointers if user can resolve.>

## Source map

<5-15 canonical file:line refs — the most important pointers from all dimensions in one place.>

## Per-dimension files

- `code.md` — full code-level findings
- `tests.md` — full test landscape
- `constraints.md` — full constraint analysis
```

<IMPORTANT>

## Anchor

- **RS-1.** Dimensions → user OK → dispatch. Never skip the OK.
- **RS-2.** One subagent per dimension, parallel, self-contained brief.
- **RS-3.** Path: `~/src/sand/docs/research/{topic-slug}/`.
- **RS-4.** Challenge every output. Spot-check refs. Re-dispatch on hallucination.
- **RS-5.** Deliverable = `REPORT.md`. Standalone. No pipeline chain.
- **RS-6.** Read files, consolidate. Never paste subagent transcripts to chat.
- **RS-7.** 2-attempt budget per dimension. Then UNRESOLVED + escalate.

</IMPORTANT>
