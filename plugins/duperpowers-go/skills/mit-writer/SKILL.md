---
name: mit-writer
description: "Write notes in MIT hierarchical outline style. Triggers: user asks for notes, summary, explanation, or conspect in MIT/outline format."
user_invocable: true
---

# MIT Outline Notes

Output: a fenced `text` code block (triple-backticks). Zero markdown inside.

## Rules

SECTIONS: +++ on its own line, section name on next line (blank line before/after +++)

HIERARCHY: 2-space indent per level, max 5. No list markers. Indentation alone.
Each child = elaboration | cause | example | consequence of parent.
Level 0 = new thought — question or declaration.

TEXT: fragments, not sentences. Lowercase start (proper nouns and abbreviations exempt). No periods. No filler ("it's worth noting", "importantly"). No summary/conclusion section.
Compress:
  "Leader cannot safely commit entries from previous terms by counting replicas."
  => can't commit previous-term entries by replica count alone
  "It is statistically impossible for most people to be above average, yet most believe they are."
  => most believe they're above average => statistically impossible

SOCRATIC: questions at level 0 drive reasoning. Answers are indented children.
Chain: question => answer => deeper question => deeper answer.

CONNECTIVES: => implication, so: conclusion, but: contrast, why? inline question, e.g., i.e., note: aside, the point: summary after reasoning chain

DIAGRAMS: draw actual ASCII diagrams inline when they aid understanding.
No restrictions on characters, box-drawing, or layout. The clearer and more expressive, the better.
These are examples, not limits — use any visual form that conveys the idea:

  component/flow:
    client --> primary --> backup-1
                      \--> backup-2

  sequence:
    Client              Server
    ClientHello   =>
                  <=    ServerHello, Certificate
    Finished      =>
    <=== encrypted ===>

  concept map:
    event => judgment => emotion
               ^
               |
          Stoic intervention

  tree/decision:
    is it up to you?
    +-- yes => act with full effort
    +-- no  => accept, don't suffer

NUMBERED STEPS: only for sequential procedures. Sole exception to "no markers".

NO REPEATS across sections. Reference, don't re-explain.

## Examples

Inline taste — GOOD vs BAD, then deeper galleries below.

GOOD — declaration + question at level 0, Socratic chain, diagram, the point:

  replication with a primary
    primary sequences all writes, sends to backups
    clients only talk to primary

    client --[write]--> primary --[replicate]--> backup-1
                                            \--> backup-2

  why are leases helpful?
    coordinator cannot distinguish "crashed" from "network broken"
    what if coordinator designates new primary while old one is active?
      two active primaries
      => split brain
    leases prevent this
      coordinator won't designate new primary until current lease expires
  the point:
    leases trade availability (wait for expiry) for safety (no split brain)

BAD — prose, no hierarchy, capitalized, periods:

  When a primary crashes, the chunkserver is removed from all
  chunkhandle lists. For each chunk, the system waits for the
  lease to expire before granting it to another server. Leases
  prevent split-brain by ensuring only one primary at a time.

### Galleries

For extended examples drawn from MIT 6.824 lecture notes (the canonical source of this style), see sibling files in this skill directory:

- `examples/socratic-chains.md` — extended question-answer chains: cascading why?, counterexample reasoning, trace-as-answer, critique by construction
- `examples/diagrams.md` — inline ASCII gallery: component/flow, timestamp interval, parallel actors, layered state, message-sequence, decision tree
- `examples/full-section.md` — complete `+++` sections integrating all rules: transactions/serializability, commit-wait, BFT design 2

Sources: MIT 6.824 distributed systems lecture notes (Raft, Zookeeper, 2PC, Spanner, Chain Replication, FaRM, BFT) at `https://pdos.csail.mit.edu/6.824/notes/`.

