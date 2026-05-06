---
name: verify
description: "Use when verifying a Go branch is in shippable state — runs gocheck (build + format + tests + vet) + dpcheck (preference analyzer, if available). Pure check, no mutation. PASS / FAIL with file:line evidence."
---

# Verify

<IMPORTANT>

## Golden Rules

- **VF-1.** Always run `gocheck` (build + format + tests + vet). Never skip — last-known-good state is not trustworthy after edits.
- **VF-2.** Run `dpcheck` if available in the tool catalog. Missing → warning, continue (do not FAIL).
- **VF-3.** Pure check. Do NOT mutate code, do NOT suggest fixes inline — only report findings. Caller decides what to do.
- **VF-4.** Output structured result: VERDICT / GOCHECK / DPCHECK / FINDINGS with file:line evidence when applicable. Collect ALL failures; do not stop at first.
- **VF-5.** When superpowers requests verification before completion (`superpowers:verification-before-completion`) on Go code — route through this skill instead of running ad-hoc commands.

## Anti-patterns

| Rationalization | Reality |
|-----------------|---------|
| "I'll fix the issue while checking, it's faster" | No — verify is pure. Report only. Caller decides what to do. |
| "Skip gocheck, user just ran build 2 min ago" | Always run. Last-known-good state is not trustworthy after edits. |
| "Treat missing dpcheck as FAIL" | No — dpcheck is optional. Missing → warning, continue. |
| "Run shell `go build` directly instead of the gocheck agent" | Use the gocheck agent — it absorbs the noisy verification cycle and reports a structured summary, preserving main context. |

</IMPORTANT>

## Usage

Invoke in the current working directory (must be a Go module root).

```
verify           # default — gocheck + dpcheck if available
verify --strict  # FAIL on dpcheck findings (default: warn)
```

## What It Runs

### gocheck (always)

Delegate to the `gocheck` Task agent (subagent). It runs (Makefile-driven, fails fast if no Makefile):

```
make build
make fast-format | make format     # optional, whichever target exists; ⊘ SKIPPED if neither
make test-all                      # full test execution, not compile-only
go vet ./...
```

On any non-zero exit → FAIL with the stderr as evidence.

Use the agent — not direct `Bash` — to keep verification noise out of main context.

### dpcheck (if available)

Availability check: consult Claude's tool catalog for `dpcheck`.

- **Available:** invoke `dpcheck --base=main ./...`. Parse output as findings.
- **Missing:** emit warning line in output, treat DPCHECK slot as `missing`, continue.

If a different flag shape is detected on the work machine, match what is available.

## Output Format

```
MODE:     verify
VERDICT:  ✅ PASS | ❌ FAIL
DPCHECK:  available | missing (warning)

GOCHECK:
  build  → ✅
  vet    → ✅
  test   → ❌ (./internal/user: compilation error on line 42)

FINDINGS (on FAIL or dpcheck warnings):
  ./internal/user/service.go:42 — undefined: helperFn
  ./internal/billing/calc.go:88 — dpcheck: unused parameter "ctx"

Duration: <wall-clock>s
```

<IMPORTANT>

## Anchor

- **VF-1.** Always gocheck — via the gocheck agent.
- **VF-2.** dpcheck optional. Missing → warning.
- **VF-3.** Pure check — no mutations, no fix suggestions.
- **VF-4.** Output structured: VERDICT / GOCHECK / DPCHECK / FINDINGS with file:line. Collect ALL failures.
- **VF-5.** Route superpowers verification-before-completion through this skill on Go code.

</IMPORTANT>
