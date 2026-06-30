# Full section — all rules integrated

Pattern: a complete `+++` section showing how SECTIONS, HIERARCHY, TEXT, SOCRATIC, CONNECTIVES, DIAGRAMS, and NUMBERED STEPS coexist. Source: MIT 6.824 lecture notes (l-2pc, l-spanner, l-raft2, l-bft).

## 1. transactions and serializability — adapted from l-2pc

```text
+++

transactions

  +++

  example: bank transfer + audit
    x and y are bank balances, both start at $10
    T1: transfer $1 from y to x
    T2: audit the total amount

      T1:               T2:
      BEGIN-X           BEGIN-X
        add(x, 1)         tmp1 = get(x)
        add(y, -1)        tmp2 = get(y)
      END-X               print tmp1, tmp2
                        END-X

  what is correct behavior for a transaction?
    "ACID"
      Atomic     -- all writes or none, despite failures
      Consistent -- obeys application invariants
      Isolated   -- no interference, serializable
      Durable    -- committed writes are permanent

  +++

  serializability test

  test result by looking for a serial order yielding the same outputs
    possible serial orders:
      T1; T2 => x=11 y=9 print "11,9"
      T2; T1 => x=11 y=9 print "10,10"
    either is OK
    no other result is OK

  what if T1 runs entirely between T2's two get()s?
    T2 prints "10,9"
    but: 10,9 is neither serial result
    => not serializable

  the point:
    serializability = property of the output, not the execution
    output indistinguishable from some serial order => OK
```

What to notice:
- nested `+++` sections under a parent section
- example precedes definition (concrete first, then ACID)
- diagram (T1/T2 columns) sits inside the outline as a level-3 child
- `but:` introduces the contradiction, `=>` collapses to verdict
- `the point:` closes with the takeaway, not a recap

## 2. why commit-wait — adapted from l-spanner

```text
+++

commit-wait gives external consistency

  setup
    T1 finishes (writes x), then T2 starts (reads x)
    we need TS1 < TS2

                  TS1=10
                  [1,10]     [11,20]
    r/w T1:         C..........W
                                       TS2=15
                                       [5,15]
    r/o T2:                              Rx

  why does this work?
    commit-wait waits until TT.now().earliest > TS1
      => TS1 is guaranteed in the past at commit
    T2 picks TS2 = TT.now().latest
      => TS2 is guaranteed in the future at start
    so:
      TS2 > TS1
      => T2 sees T1's writes

  cost:
    every write transaction waits ~7ms (typical TrueTime epsilon)
    => latency for safety
```

What to notice: setup -> diagram -> Socratic "why does this work?" -> chained `=>` reasoning -> closing `cost:` aside that names the trade-off explicitly.

## 3. structuring "what NOT to do" — adapted from l-bft

```text
+++

design 2: voting with 2f+1 servers

  client sends op to all
  client waits for f+1 matching replies
    rationale: f bad nodes can't dominate f+1 matching answers

  what's wrong with this?
    f+1 matching replies might be f bad + 1 good
      so maybe only one good node got the operation
    next operation also waits for f+1
      might not include that one good node
    example:
      f, g1, g2          (f = faulty)
      all hear write("A"), all reply
      f and g1 reply to write("B"), g2 misses it
        client can't wait for g2 -- could be the faulty one
      f and g2 reply to read(), g1 misses it
      => read() returns "A" (stale)
    the point:
      f+1 quorum is too small
      no overlap guarantee between successive operations
      => need 2f+1 quorum
        with 3f+1 servers
```

What to notice: design statement -> rationale -> "what's wrong?" -> abstract flaw -> concrete trace with named actors -> `the point:` -> the FIX named at the end. Reader walks the failure before learning the correction. This is the canonical MIT shape for introducing an algorithm.
