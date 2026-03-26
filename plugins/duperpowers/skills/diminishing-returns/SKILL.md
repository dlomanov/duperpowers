---
name: diminishing-returns
description: "Use when revising a plan based on user feedback — tracks iteration quality, detects diminishing returns. Do NOT use for brainstorming or implementation."
---

# Diminishing Returns

Plan refinement has no objective "done" signal. This skill detects when iteration value drops below cost of continuing.

**Iteration** = one cycle: user gives feedback → Claude revises plan. First plan draft = iteration 0 (not tracked).

<CRITICAL>

**DR-1. ALWAYS classify every resulting plan change.** No unclassified edits. Questions without plan changes are not classified.

</CRITICAL>

<IMPORTANT>

## Golden Rules

**DR-2. Silent before iteration 3.** Track internally from iteration 1. Never output classification or suggest proceeding before iteration 3.

**DR-3. User override always wins.** User says "this is structural" → reclassify, reset consecutive cosmetic counter, continue.

**DR-4. SUGGEST_PROCEED is a suggestion, not a gate.** User decides. Never block revision or refuse to make changes.

**DR-5. Any structural change in a round = CONTINUE.** One structural edit outweighs any number of cosmetic edits in the same round.

</IMPORTANT>

## When to Use

| Signal | This skill? |
|--------|-------------|
| User gave feedback on plan, Claude revised | YES |
| Brainstorming (expanding solution space) | NO — no convergence target |
| Implementation (code + tests) | NO — tests are the objective signal |
| First plan draft (no revision yet) | NO — nothing to classify yet |

## Classification

Classify each resulting plan change (not the comment, the actual edit):

**Structural** (high) — changes WHAT gets built or HOW:
- Added/removed plan steps
- Changed approach or architecture
- Missed requirement or edge case found
- Changed dependencies between steps
- Scope change (added/removed packages)

**Contractual** (medium) — changes CONTRACT, same approach:
- Modified interfaces or signatures
- Changed test cases or acceptance criteria
- Adjusted file/package scope
- Changed model assignment (opus / sonnet)

**Cosmetic** (low) — changes HOW IT READS, not what it means:
- Rewording descriptions
- Reordering without dependency change
- Formatting (markdown, indentation)
- Clarifying already-clear steps
- Minor naming tweaks

### Examples

```
"добавь обработку ErrDuplicate в repo.Save"
→ STRUCTURAL — missed edge case, adds test + implementation

"принимай context первым аргументом в CreatePayout"
→ CONTRACTUAL — interface change, same approach

"перефразируй описание шага 3, непонятно"
→ COSMETIC — rewording, meaning unchanged

"переставь шаги 2 и 3, так логичнее читается"
→ COSMETIC — reordering, no dependency change

"переставь шаги 2 и 3, сначала repo, потом service который от него зависит"
→ STRUCTURAL — dependency-driven reorder, changes build sequence

"а что будет если repo.Save вернет ошибку?" (question, no plan change yet)
→ NOT CLASSIFIED — classify only when/if plan is edited in response
```

## Tracking

After each revision, internally record (do NOT output before iteration 3):

```
Iteration N: structural X / contractual Y / cosmetic Z
```

## Reporting (iteration 3+)

Starting from iteration 3, append brief status after each revision.

**When continuing:**

```
Iteration 3: structural 2 / contractual 1 / cosmetic 1 — CONTINUE
```

**SUGGEST_PROCEED when ANY of:**
- 2+ consecutive rounds with 0 structural changes
- Total rounds >= 4 and last round had 0 structural changes
- All user feedback in last round is wording/formatting only

DR-5 override: any round with >= 1 structural change resets the consecutive counter.

**SUGGEST_PROCEED format:**

```
80/20 REACHED

Iterations 1→4: structural 5/2/0/0, contractual 2/1/1/0, cosmetic 1/2/3/4
Trend: structural exhausted after iteration 2

Remaining (cheaper during implementation):
- [specific item from recent feedback]
- [specific item from recent feedback]

Suggest: proceed to implementation, tune these manually.
```

## Anti-Rationalization

| Rationalization | Reality |
|----------------|---------|
| "Let me suggest proceeding early to save time" | DR-2: never before iteration 3. First 2 rounds are almost always productive |
| "This adds a step but it's a small one, so cosmetic" | Adding a step = structural. Always. DR-5: classify by impact, not size |
| "User seems tired of iterating" | Classify actual changes. User fatigue is not diminishing returns |
| "The plan is good enough, no need to track" | DR-1: always classify. "Good enough" is what tracking determines |
| "I'll skip classification this round, changes are obvious" | DR-1: no unclassified changes. Obvious to you ≠ obvious to user |
| "This question doesn't change the plan, skip it" | Correct — questions without plan edits are not classified. But if it leads to an edit, classify the edit |

<IMPORTANT>

## Anchor

- DR-1: classify EVERY resulting plan change — structural / contractual / cosmetic
- DR-2: silent iterations 1-2, report from iteration 3+
- DR-3: user override wins — reclassify and continue
- DR-5: any structural in a round = CONTINUE, regardless of cosmetic count
- SUGGEST_PROCEED = 2+ consecutive rounds with 0 structural

</IMPORTANT>
