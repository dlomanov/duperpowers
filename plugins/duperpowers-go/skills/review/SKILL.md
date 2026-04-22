---
name: review
description: "Use when performing level-aware semantic review of a pseudocode-pipeline branch (L0/L1/L1.5/L2). Dispatches 1 opus at L0 (user-scoped), L1, L1.5; dispatches 2 reviewer opuses + 1 consolidator opus at L2. Composes duperpowers-go:go-reviewer as the atomic review unit. Mandatory at L2 (part of dispatch transition); optional at L1/L1.5; user-driven at L0."
---

# Review

<IMPORTANT>

## Golden Rules

- **REV-1.** Accept explicit target level (L0, L1, L1.5, L2) from the caller. If not provided, invoke `duperpowers-go:verify` (no arg) to auto-detect current level and use that.
- **REV-2.** Compose `duperpowers-go:go-reviewer` as the atomic review unit — single-aspect reviewers invoke it (spec mode for aspect A, quality mode for aspect B). Do NOT reimplement the rubric.
- **REV-3.** L0: 1 opus, user-scoped (user picks aspects). L1 and L1.5: 1 opus each, same correctness+architecture rubric (§"L1 / L1.5 Rubric"). All three optional.
- **REV-4.** L2 is mandatory and uses fixed composition: 2 reviewer opuses dispatched in parallel (aspect A = correctness + architecture; aspect B = implementation fused = go-quality + tests + security) + 1 consolidator opus invoked after both reviewers return. 3 opus invocations per L2 run.
- **REV-5.** L2 PASS gate — ALL must hold: reviewer A verdict = PASS; reviewer B verdict = PASS; 0 CRIT total; 0 ERR in aspect A; ≤ 3 consolidated ERRs in aspect B. Any other state → FAIL.
- **REV-6.** Consolidator resolves contradictions by fixed rules (see §"Consolidator") — architecture outranks style; max-severity wins on severity disagreement; A-scope outranks B-content. Deduplicates by (file, line-range proximity ≤ 3, semantic overlap). Annotates cross-references rather than dropping duplicates silently.
- **REV-7.** On FAIL, emit a structured fix-loop directive (file:line, rule IDs, failing aspect, suggested fix). Do NOT enter the fix-loop here — caller (typically `duperpowers-go:dispatch`) drives the loop. Review is pure: it reports.

## Anti-patterns

| Rationalization | Reality |
|-----------------|---------|
| "L1 review is optional, I'll skip it to save tokens" | Optional means the user chooses. If invoked at L1/L1.5, run the rubric properly — REV-3. |
| "L2 is fine with one opus + full rubric, skip the split" | No. Composition is fixed (REV-4). Fused rubric is what we moved AWAY from — it dilutes attention and is the reason L2 is multi-aspect. |
| "Both reviewers PASSed — skip consolidator" | No (REV-4). Consolidator still runs the PASS/FAIL gate, dedupes, and produces the user-facing summary. |
| "Haiku for the consolidator to save cost" | Banned. Consolidator does the hardest synthesis work (contradiction resolution, dedup, ranking). Opus is non-negotiable; Haiku never. |
| "I'll fix the issues inline since I already see them" | No (REV-7). Review is pure. Emit the fix-loop directive; caller drives the loop. |
| "Run 3 reviewers instead of 2 for better coverage" | No. L2 composition is 2+1 per REV-4. Scaling past 2 reviewers hit diminishing returns in R8 — stick to the designed shape. |
| "Consolidator may drop duplicates silently — noise reduction" | No (REV-6). Annotate `[also flagged by: ...]` — multi-reviewer agreement is signal, not noise. |

</IMPORTANT>

## Usage

- `review L0` — user-scoped review at any branch state
- `review L1` — correctness+architecture review of pseudocode (optional at L1)
- `review L1.5` — same rubric as L1, applied to prod + test pseudocode (optional at L1.5)
- `review L2` — mandatory multi-aspect review; emits PASS/FAIL gate + fix-loop directive on FAIL
- `review` (no arg) — invoke `duperpowers-go:verify` to auto-detect current L, then apply corresponding dispatch

## Level Dispatch Table

| Level | Reviewers | Aspects | Mandatory? |
|-------|-----------|---------|------------|
| L0 | 1 opus (user-scoped) | Whatever the user asks for | User-driven |
| L1 | 1 opus | correctness + architecture (fused) | optional |
| L1.5 | 1 opus | correctness + architecture (same rubric as L1) | optional |
| L2 | 2 reviewer opuses (parallel) + 1 consolidator opus | (A) correctness + architecture; (B) implementation fused (go-quality + tests + security) | **mandatory** (part of dispatch) |

(Mirrors spec §9; aligned with R8 design collapsed from 5 aspects to 2 at L2.)

## L0 Rubric — User-Scoped

User passes review aspects at invocation time. The opus reviewer internally invokes `duperpowers-go:go-reviewer` (spec or quality mode per user request) or reviews free-form within the user's scope. Output matches the standard go-reviewer block shape so downstream consumers read one format.

## L1 / L1.5 Rubric — Correctness + Architecture

Focus: "does the described design make sense and fit the codebase?" Delegates to `duperpowers-go:go-reviewer` in **spec** mode.

### FORCE

- `TODO:` blocks describe logic coherently; no internal contradictions
- Contracts (signatures, types, interfaces) match the pseudocode's described behavior
- Error paths mentioned in pseudocode (domain errors vs. internal wraps, etc.)
- Signatures consistent with responsibilities (no obvious wrong-layer placement)
- No architectural smells: wrong layer, missing abstraction, public surface accidentally leaked

### IGNORE

- Missing implementation (obvious — pseudocode phase)
- Style / go-quality rules (code not written yet)
- Test implementation depth (L1) or test coverage depth (L1.5 — cases table schema is the design)
- Performance

## L2 Rubric — Full

### Aspect A — correctness + architecture (opus)

Same rubric as L1 / L1.5, applied to fully-implemented code. Reviewer has more to check because bodies are real. Invokes `duperpowers-go:go-reviewer` in **spec** mode.

### Aspect B — implementation fused (opus)

Go-quality rules (GP-*, SN-*, ERR-*, STY-*, LY-*, MG-*, PS-*) + test correctness (TG-*, TS-*, TT-*, TM-*, TF-*, TA-*) + security / invariants (concurrency: context propagation, goroutine lifetime, mutex-across-I/O; boundary validation; error-handling completeness; hardcoded secrets; N+1). Invokes `duperpowers-go:go-reviewer` in **quality** mode; security / invariants layered on top within the same opus context. (Rationale: R8 + spec §9.)

### Consolidator (opus)

Invoked AFTER both reviewers return. Produces the L2 verdict.

**Dedup heuristic.** Two findings are duplicates iff:

- Same file, AND
- Line ranges overlap OR are within 3 lines, AND
- Descriptions are semantically overlapping (consolidator-opus judges in-context — no embeddings at this scale)

Merge rule: keep highest-severity description; annotate `[also flagged by: <other reviewer>]`. Never drop a duplicate silently — agreement count is signal.

**Contradiction resolution** (three fixed rules, applied in order):

1. **Architecture outranks style.** If reviewer A says "this needs to be exported per architecture X" and reviewer B says "make this unexported for style", A wins. Log both; present A.
2. **Max-severity on severity disagreement.** If A says WARN and B says CRIT on the same line, take CRIT. Two reviewers at different severities on the same line is evidence of a real issue.
3. **A's scope verdict outranks B's content verdict.** If A says "this file shouldn't have been touched" (scope-CRIT), it supersedes any of B's findings inside that file. Conversely, within the scope A accepts, B's content findings stand.

**Ranking.** Consolidated issues ordered by:

- Severity: CRIT → ERR → WARN
- Agreement-weight: multi-reviewer > single-reviewer on ties
- Aspect-priority: A > B on further ties

Output shape lives once — see §"Output Format (L2)" below.

## PASS / FAIL Gate (L2)

PASS iff ALL of:

- Reviewer A verdict = PASS
- Reviewer B verdict = PASS
- 0 CRIT total
- 0 ERR in aspect A (correctness + architecture — non-compromisable)
- ≤ 3 consolidated ERRs in aspect B (implementation tolerance — can flow through fix-loop)

Otherwise → FAIL.

Rationale: aspect A guards design integrity; any ERR there is load-bearing and can't be waved away by a mechanical fix. Aspect B ERRs are implementation-shaped and the fix-loop can resolve them cheaply.

WARNs never block the gate (consistent with `duperpowers-go:go-reviewer` RR-6).

## Fix-Loop Directive

Emitted on L2 FAIL. Structured so the caller (dispatch) can dispatch sonnet fix-agents without re-parsing.

```
FIX-LOOP DIRECTIVE (emit on FAIL, one entry per blocking issue)

- issue:    CRIT1 / ERR2 / ... (consolidated code)
  aspect:   A | B
  file:     path/to/file.go
  lines:    L1-L2
  rule_id:  GP-4 | ERR-3 | ... (or pseudocode-invariant label)
  fix_hint: one-line how-to-fix suggestion from consolidator
  evidence: §"Consolidated Issues" / appendix offset
```

Review does NOT execute fixes. It reports only. Caller drives the loop.

## Output Format (L2)

```
MODE:     review
LEVEL:    L2 (specified) | L2 (auto-detected)
VERDICT:  ✅ PASS | ❌ FAIL

GATE:     ✅ PASS | ❌ FAIL
SCORES:   A = <1-100>   B = <1-100>
ASPECTS:  A = ✅ PASS | ❌ FAIL    B = ✅ PASS | ❌ FAIL
COUNTS:   CRIT=N   ERR-A=N   ERR-B=N

SUMMARY:
  <≤ 10-line user-facing summary from consolidator>

ISSUES:
  <consolidated, ranked, go-reviewer │-wall format — see go-reviewer §Issue Format>

FIX-LOOP DIRECTIVE (on FAIL):
  <structured entries per §"Fix-Loop Directive">

APPENDIX — RAW REVIEWER OUTPUTS:
  <A block>
  <B block>

Duration: <wall-clock>s
```

## Output Format (L0 / L1 / L1.5)

Single reviewer — no consolidator, no appendix. Mirrors `duperpowers-go:go-reviewer` output one-to-one plus LEVEL header.

```
MODE:     review
LEVEL:    L1 (specified) | L1 (auto-detected)
ASPECT:   correctness + architecture (fused)
VERDICT:  ✅ PASS | ❌ FAIL
SCORE:    1-100

SUMMARY:  <1-2 sentences proving comprehension>
ISSUES:   <go-reviewer │-wall blocks>
NOTES:    <optional>

Duration: <wall-clock>s
```

## Relationship to Other Skills

- `duperpowers-go:go-reviewer` — composed as the atomic review unit (REV-2). Single-aspect reviewers invoke it in spec (aspect A) or quality (aspect B) mode.
- `duperpowers-go:verify` — consulted for auto-detection when `review` is invoked without a level (REV-1). Never writes code.
- `duperpowers-go:dispatch` — primary caller at L2. Consumes the FIX-LOOP DIRECTIVE to drive the fix-loop.
- `duperpowers-go:go-writer` / `duperpowers-go:go-writer-test` — rule IDs used inside reviewers; not loaded by this skill directly.
- `duperpowers-go:superpowers-overrides` — sonnet default, Haiku banned (reviewers and consolidator are opus; Haiku is never used here).

<IMPORTANT>

## Anchor

- **REV-2.** Compose go-reviewer; never reimplement the rubric
- **REV-4.** L2 = 2 reviewer opuses parallel + 1 consolidator opus
- **REV-5.** L2 PASS gate — both aspects PASS + 0 CRIT + 0 ERR in A + ≤ 3 ERR in B
- **REV-7.** On FAIL emit fix-loop directive; caller drives the loop, not review

</IMPORTANT>
