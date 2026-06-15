# Socratic chains - extended examples

Pattern: question at level 0 -> indented answer -> deeper question -> deeper answer. Drives the reader through reasoning instead of stating conclusions. Source: MIT 6.824 lecture notes.

## 1. cascading "why?" - persistence in Raft (l-raft2)

```text
if a server crashes and restarts, what must Raft remember?
  Figure 2 lists "persistent state":
    log[], currentTerm, votedFor
  a Raft server can only re-join after restart if these are intact
  thus it must save them to non-volatile storage
  why log[]?
    if a server was in leader's majority for committing an entry,
      must remember entry despite reboot
  why votedFor?
    to prevent a client from voting for one candidate, then reboot,
      then vote for a different candidate in the same term
    could lead to two leaders for the same term
  why currentTerm?
    avoid following a superseded leader
    avoid voting in a superseded election
```

What to notice: one umbrella question, three parallel sub-questions, each answered with cause + consequence. No prose glue.

## 2. counterexample reasoning - unilateral abort in 2PC (l-2pc)

```text
What if B replied YES to PREPARE, but doesn't receive COMMIT or ABORT?
  Can B unilaterally decide to abort?
    No
    TC might have gotten YES from both
    and sent COMMIT to A, but crashed before sending to B
    so then A would commit and B would abort
    => incorrect
```

What to notice: question -> proposed shortcut -> "No" + scenario that breaks it -> `=>` collapses scenario to verdict. The reasoning IS the answer.

## 3. trace-as-answer - election restriction in Raft (l-raft2)

```text
why not elect the server with the longest log as leader?
  it would overwrite 103 at 2, which could be committed by 1 and 2
  who should be next leader?
    end of 5.4.1 explains the "election restriction"
    RequestVote handler only votes for candidate "at least as up to date":
      candidate has higher term in last log entry, or
      candidate has same last term and same length or longer log
  so:
    S1 and S2 won't vote for P0
    S1 and S2 will vote for each other
  so only S1 or S2 can be leader, will force S0 to discard 102, 103, 104
    ok since those are not on majority
    => not committed
    => reply never sent
```

What to notice: rhetorical question, then a *trace* through specific server names answers it. `so:` chains the conclusion. `=>` chains terminal consequences.

## 4. critique by construction - BFT design 2 fails (l-bft)

```text
what's wrong with design 2's 2f+1?
  f+1 matching replies might be f bad nodes and just 1 good
    so maybe only one good node got the operation
  next operation also waits for f+1
    might not include that one good node that saw op1
  example:
    f g1 g2          (f is faulty)
    everyone hears and replies to write("A")
    f and g1 reply to write("B"), but g2 misses it
      client can't wait for g2 since it may be the one faulty server
    f and g2 reply to read(), but g1 misses it
    so read() yields "A"
  the point:
    client tricked into accepting a reply based on out-of-date state
```

What to notice: abstract flaw -> concrete trace with named actors -> `the point:` distills the trace into one line. Closing line is the takeaway, not a summary of preceding text.
