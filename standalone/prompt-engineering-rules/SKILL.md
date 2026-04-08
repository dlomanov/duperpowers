---
name: prompt-engineering-rules
description: "Reference for writing/editing CLAUDE.md, SKILL.md, and any AI instruction files. Sorted by measured impact."
---

# Prompt Engineering Rules for AI Skill Files

Reference document. Apply when writing/editing CLAUDE.md, SKILL.md, any AI instruction files.
Sorted by measured/observed impact. IDs are append-only.

## Tier 1 — Measured Impact

**PR-1. Anti-rationalization tables.** List thoughts the LLM might generate to skip a rule, close each escape path. Format: "Rationalization -> Reality". Compliance 33%->72% (N=28000).

**PR-2. Positive > negative.** "ALWAYS use X" instead of "Don't use Y". ~50% fewer violations.

**PR-3. GOOD/BAD code blocks.** Every rule with code implications gets a GOOD/BAD example. Most reliable format for sonnet. Code > prose. GOOD/BAD for style, Before/After for version migrations.

**PR-4. Golden Rules + Anchor.** 5-7 non-negotiable principles at document top in `<IMPORTANT>`. Repeat them briefly at the bottom (Anchor section). LLMs have primacy/recency bias -- middle gets lost.

**PR-5. Bright-line rules.** Imperative language without exceptions. "YOU MUST", "ALWAYS", "No exceptions". Removes decision fatigue.

## Tier 2 — Expert Consensus

**PR-18. Shortest possible sentences.** Write rules in plain direct language. No subordinate clauses, no jargon, no hedge words. One idea per sentence.

**PR-19. Representative examples, not edge cases.** Examples teach the model what "normal" looks like. 3 diverse common-case examples build the mental map. Edge cases without a baseline teach the exception, not the rule. Cover the territory, then add boundaries.

BAD: only edge cases (empty input, nil, overflow). GOOD: 3 common cases first, then 1 edge case.

**PR-6. 30-line core + rich examples.** Core rules fit in ~30 lines. GOOD/BAD examples add length but worth the tokens for sonnet comprehension. Core is tight, examples are rich.

**PR-7. 3-5 examples per format.** Most reliable way to stabilize output format. Examples > descriptions.

**PR-8. Token efficiency.** Each line must pass: "If I remove this, will the model make a mistake?" If no -- remove. System prompt already has ~50 instructions; your rules compete for ~100-150 remaining slots.

**PR-9. General -> Specific.** Philosophy first, project-specific corners last. Reader builds mental model progressively.

**PR-10. Progressive disclosure.** "Look at neighboring *_test.go for patterns" instead of hardcoding all patterns. Tell HOW to find info, don't dump everything.

## Tier 3 — Good Practice

**PR-11. Stable IDs.** Each rule gets a unique ID (GP-1, ERR-2, STY-3). Reviewer references: "violates GP-3 file:line". IDs are append-only -- never reuse deleted IDs.

**PR-12. STOP escalation.** Explicit stop points: "If X happens x2, STOP and report BLOCKED". Prevents infinite retry loops.

**PR-13. XML tags.** `<IMPORTANT>`, `<CRITICAL>` for high-priority sections. Claude trained on XML, assigns structural weight.

**PR-14. Real codebase examples.** Use actual code from the project as GOOD/BAD, then anonymize. Proves the rule is grounded, not invented.

**PR-15. No duplication across files.** Same rule in CLAUDE.md AND skill -> wasted tokens. Single source of truth. Agents MUST load skills -> remove duplicates from CLAUDE.md.

**PR-16. Don't restate system prompt.** System prompt handles generic practices. Skills = project-specific conventions only.

**PR-17. Severity levels.** MUST / SHOULD / CAN. Removes ambiguity when rules conflict.

## Sources

- superpowers plugin analysis -- anti-rationalization (PR-1), STOP escalation (PR-12)
- TechLoom benchmark (1188 runs) -- positive framing +0.66 pts (PR-2)
- JetBrains/go-modern-guidelines -- GOOD/BAD format (PR-3)
- darrenoakey/claude-skill-golang -- Golden Rules (PR-4)
- dev.to "5 Patterns That Make Claude Code Follow Your Rules" -- anchoring (PR-4), token efficiency (PR-8)
- Anthropic best practices -- examples (PR-7), XML tags (PR-13)
- HumanLayer "Writing a Good CLAUDE.md" -- progressive disclosure (PR-10), system prompt (PR-16)
- maxdml CLAUDE.md gist -- Stable IDs (PR-11), severity levels (PR-17)
