# Inline ASCII diagrams — extended examples

Pattern: a diagram is part of the outline, not a sidebar. Place it where a child would go and let surrounding indentation frame it. Source: MIT 6.824 lecture notes.

## 1. component / flow — chain replication topology (l-cr)

```text
the basic chain replication arrangement
  clients         CFG (= master)
       \          /
        v        v
       S1 ---> S2 ---> S3
      head            tail

  clients send updates to head
    head picks an order (assigns sequence numbers)
    head updates local replica, sends to S1
    S1 updates, sends to S2
    S2 updates, sends to S3
    S3 updates, sends response to client
```

What to notice: diagram first, then numbered-style behavioral list as children. The diagram replaces an English description of the topology.

## 2. timestamp / interval — Spanner commit-wait (l-spanner)

```text
why commit-wait gives external consistency
              TS1=10
              [1,10]     [11,20]
  r/w T1:       C..........W
                                  TS2=15
                                  [5,15]
  r/o T2:                           Rx

  given that T1 finishes before T2 starts
  commit-wait => TS1 guaranteed in the past
  TS2 = TT.now().latest => guaranteed in the future
  => TS2 > TS1
  => T2 sees T1's writes
```

What to notice: diagram shows time on the horizontal axis, transactions on rows, intervals as `[...]`. Reasoning beneath chains `=>` to walk from "given" to "concluded".

## 3. parallel actors — Zookeeper "ready" znode scheme (l-zookeeper)

```text
what if MR coord stores state in multiple znodes?
  use paper's "ready" znode scheme
    delete "ready"; update znodes; create "ready"

    leader:                       worker:
      delete(s, "ready")
      setData(s, z1)
      setData(s, z2)              if exists("ready", watch=ready):
      create(s, "ready")            read z1
                                    read z2
```

What to notice: two columns labeled with actor names; vertical position implies time within each column; gap shows that worker waits. No arrows needed when columns are aligned.

## 4. layered state — FaRM region layout (l-farm)

```text
server memory layout
  regions, each an array of objects
    object layout
      header
        version#
        lock flag (high bit of version#)
  for each other server:
    incoming log
    incoming message queue
  all in non-volatile RAM
    written to SSD on power failure
```

What to notice: no boxes, no arrows — pure indentation as containment. Each level is "X contains Y". Tightly compressed.

## 5. message-sequence — BFT three-phase protocol (l-bft)

```text
operation protocol
  client sends op to primary
  primary sends PRE-PREPARE(op, n) to all
  all send PREPARE(op, n) to all
  after replica receives 2f+1 matching PREPARE(op, n):
    send COMMIT(op, n) to all
  after receiving 2f+1 matching COMMIT(op, n):
    execute op
```

What to notice: numbered-style steps without markers (rule already permits indentation alone). Each line names sender, message, recipient. Compact.

## 6. decision tree — Stoic dichotomy of control (illustrative)

```text
is it up to you?
  yes => act with full effort
  no  => accept, don't suffer
```

What to notice: minimal tree using `=>` as branch arrow. Two-line decision diagram is often enough.
