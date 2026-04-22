---
name: verify
description: "Use when checking branch state against pseudocode-pipeline level guarantees (L0/L1/L1.5/L2). Runs gocheck + dpcheck + level-specific invariants. Returns PASS/FAIL with missing-guarantees list."
---

# Verify

<IMPORTANT>

## Golden Rules

- **VF-1.** Accept explicit target level (L0, L1, L1.5, L2) from caller. If not provided, auto-detect per §"Level Detection".
- **VF-2.** Always run `gocheck` (build + vet + test compile).
- **VF-3.** Run `dpcheck` if available in Claude's tool catalog. On L0/L1/L1.5, missing `dpcheck` → warning (continue). On L2, missing `dpcheck` → FAIL.
- **VF-4.** Run level-specific guarantee checks. Collect ALL failures; do not stop at first.
- **VF-5.** Output structured result: MODE / LEVEL / VERDICT / DPCHECK / MISSING with file:line evidence when applicable.
- **VF-6.** Pure check function. Do NOT mutate code, do NOT suggest fixes inline — only report missing guarantees. Writer-skills and the user fix them.

## Anti-patterns

| Rationalization | Reality |
|-----------------|---------|
| "I'll fix the issue while checking, it's faster" | No — verify is pure. Report only. Caller decides what to do. |
| "Skip gocheck, user just ran build 2 min ago" | Always run. Last-known-good state is not trustworthy after edits. |
| "Auto-promote verdict to higher level if more guarantees hold than target" | No — the target level is a request, not a floor. Return PASS at the requested level only. Auto-detect only applies when NO target was specified (VF-1). |
| "Treat missing dpcheck as PASS on L2 since rare tools can go missing" | No — L2 requires dpcheck. FAIL is correct. |

</IMPORTANT>

## Usage

Invoke in the current working directory (must be a Go module root).

- `verify L0` — check clean-state (no pipeline artifacts)
- `verify L1` — check production pseudocode guarantees
- `verify L1.5` — check L1 + test pseudocode guarantees
- `verify L2` — check L1.5 + completed implementation guarantees
- `verify` (no arg) — auto-detect current level

## Level Detection (when target not specified)

Run checks in order; the first level whose ALL guarantees pass is the current level. Stop at first full-pass.

1. **L2** candidate: if `grep -r 'TODO:' --include='*.go' .` in changed scope = 0 matches AND `go test ./...` passes AND `plan.md` exists
2. **L1.5** candidate: if `TODO:` markers exist AND each new exported function in the diff has a `*_test.go` file with a populated cases table
3. **L1** candidate: if `TODO:` markers exist AND `gocheck` passes
4. **L0** otherwise

## Guarantees (referenced from spec §4)

### L1 guarantees

- **G1.1** Public signatures of new/changed methods compile — enforced transitively by G1.4
- **G1.2** Types, fields, models, interfaces compile — enforced transitively by G1.4
- **G1.3** At least one `TODO:` marker present in branch diff (block `/* TODO: */` or inline `// TODO:`)
- **G1.4** `gocheck` passes (build + vet + test compile)
- **G1.5** `dpcheck` passes (if available; warn if missing)

### L1.5 guarantees

- All L1 guarantees
- **G1.5.1** Each new exported function/method in the diff has a corresponding `*_test.go` file
- **G1.5.2** Test functions contain a populated `cases` slice (non-empty rows with name, input, expected)
- **G1.5.3** `t.Run` and setup closures contain `TODO:` markers or real-Go scaffolding
- **G1.5.4** Existing tests modified in the diff carry `TODO:` markers at modification sites
- **G1.5.5** `go test -count=0 ./...` compiles (failures allowed; bodies unimplemented)

### L2 guarantees

- All L1.5 guarantees
- **G2.1** `grep 'TODO:' --include='*.go'` in changed scope = 0 matches
- **G2.2** `go test ./...` passes (no failures)
- **G2.3** Latest `review` verdict = PASS (when invoked as part of dispatch)
- **G2.4** `plan.md` exists and is non-empty (dispatch artifact)

## Check Implementation

### gocheck

Always runs. Sequence:

```
go build ./...
go vet ./...
go test -count=0 ./...     # compile-only, no execution
```

On any non-zero exit → FAIL with the stderr as evidence.

### dpcheck

Availability check: consult Claude's tool catalog for `dpcheck`.

- Available: invoke with level hint, e.g. `dpcheck --level=L1 --base=main ./...`. Parse output as findings.
- Missing on L0/L1/L1.5: emit warning line in output, treat DPCHECK slot as `missing`, continue.
- Missing on L2: emit FAIL with message "dpcheck required on L2, not available".

Invocation: `dpcheck --level=<L0|L1|L1.5|L2> --base=main ./...`. If a different flag shape is detected on the work machine, match what is available.

### `TODO:` marker detection

Use ripgrep for signal-clean output:

```
rg -n 'TODO[:\[]' --type go
```

Matches both plain `TODO:` and group-tagged `TODO[group]:`. Report per-file counts; empty-count on L2 is required, non-empty on L1/L1.5 is required.

### Diff-based exported-function detection (L1.5 G1.5.1)

Enumerate newly-exported symbols in changed non-test `*.go` files (via `go doc -all` or AST). For each, verify a matching `*_test.go` exists in the same package.

## Output Format

```
MODE:     verify
LEVEL:    L1 (specified) | L1 (auto-detected)
VERDICT:  ✅ PASS | ❌ FAIL
DPCHECK:  available | missing (warning) | missing (FAIL — L2 required)

MISSING (on FAIL):
  G1.3 — no TODO: markers found in branch diff
  G1.4 — gocheck failed: <stderr excerpt>
  G1.5 — dpcheck findings: <path/to/file.go:N — <dpcheck message>>

GOCHECK:
  build  → ✅
  vet    → ✅
  test   → ❌ (./internal/user: compilation error on line 42)

Duration: <wall-clock>s
```

<IMPORTANT>

## Anchor

- **VF-1.** Explicit level or auto-detect
- **VF-2.** Always gocheck
- **VF-3.** dpcheck mandatory on L2, optional below
- **VF-6.** Pure check — no mutations, no fix suggestions

</IMPORTANT>
