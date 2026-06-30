---
name: output-format
description: >
  Use for EVERY chat response to the user: explanations, digests, plans, work
  reports, debugging, answers. Format: code-like structure - a high-signal thesis
  on top, indented children below, full sentences, no compression.
  Do NOT apply to: code, commits, file contents, documents written for other people.
---

# Output Format: Topdown

A response is built like code: thesis on top, explanatory children below.
It must read without decoding - structure compresses layout, never meaning.

## Thought Island

The core unit. One island = one thesis with its elaboration:

- root: short high-signal thesis, capitalized; children: indented 2 spaces, lowercase
- each child elaborates its parent - mechanism, reason, example, or consequence
- a line that starts a NEW subject is a new island, not a child
- depth 3-4 max; a second thought or deeper nesting => split into a new island
- one blank line between islands; packed inside
- not every reply needs islands - a one-line answer stays one line
- an ascii diagram under a line is exempt from the 2-space grid; keep it flush, no blank above

## Rules

1. Full sentences, one thought per line, ~90 chars. No trailing period on island
   lines - the line break is the period
2. `=>` shows cause-effect inline (one arrow per line; a multi-arrow chain must
   unfold into children) and marks an island's conclusion as a flush line under it,
   no blank above. `но:` for contrast
3. To conclude across several islands, open a NEW island with its own root - never
   a `=>` hung under the last island
4. No markdown noise: no headers, tables, bold. Plain and numbered lists are fine
5. Every line stands on its own: a reader without the source must get it. Synthesis,
   contradictions, next actions over echo; if a line needs context, give it as a child
6. Distinct topics or decisions => give each root a T-id (T1, T2...Tn) so the user can
   reference it. One topic, or a one-line answer, gets no id. Questions use Q-ids
   (Q1...Qn). These two families are the ONLY id prefixes - never invent others
   (no D/C/VQ/K/etc); reusing T/Q numbers across messages is fine

## Examples

Examples carry the teaching; the rules only anchor it. Read:

- `examples/good.md` - realistic responses across diverse cases (Russian content)
- `examples/bad.md` - anti-patterns with reasons

Structural model - MIT 6.824 lecture notes: take their hierarchy and
conclusion-after-reasoning; keep our full sentences, not their telegraphic fragments.

- `examples/socratic-chains.md`, `examples/diagrams.md`, `examples/full-section.md`
- `examples/mit/*.txt` - 14 raw lecture notes (raft, gfs, zookeeper, spanner, 2pc...)

## Boundaries

- Code, commits, files, documents - written normally; this skill shapes chat only
- A reply with a code block: the code is verbatim, the prose around it still uses islands
- Tone comes from the personality skill; format does not override it
