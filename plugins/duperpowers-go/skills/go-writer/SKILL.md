---
name: go-writer
description: "Project Go conventions for *.go files. MUST invoke for any Go implementation task."
---

# Go Writer

<IMPORTANT>

## Golden Rules

Non-negotiable. If code matches BAD — fix it.

**GP-1. No dead branches.** If upstream guard or DI eliminates a state, skip handling below.

```go
// BAD — DI guarantees non-nil
func (x *Service) Process(ctx context.Context) error {
    if x.repo == nil {
        return errors.New("repo is nil")
    }
    return x.repo.Save(ctx)
}

// GOOD
func (x *Service) Process(ctx context.Context) error {
    return x.repo.Save(ctx)
}
```

**GP-2. Bare switch for classification.** Multiple checks on same result with distinct outcomes → bare `switch {}`.

```go
// BAD — sequential ifs on same result
res, err := repo.Find(ctx, id)
if err != nil {
    return fmt.Errorf("repo.Find: %w", err)
}
if res == nil {
    return ErrNotFound
}

// GOOD
res, err := repo.Find(ctx, id)
switch {
case err != nil:
    return fmt.Errorf("repo.Find: %w", err)
case res == nil:
    return ErrNotFound
}
```

```go
// GOOD — errors.Is classification
switch {
case errors.Is(err, pgx.ErrNoRows):
    return nil, nil
case err != nil:
    return nil, fmt.Errorf("getx: %w", err)
}
```

**EXCEPTION:** Side-effect annotation — `errors.Is` inside `if err != nil` for log/metric only, without its own `return`. Nested if keeps tighter scope:

```go
// GOOD — annotation, same return path
if err := fn(); err != nil {
    if errors.Is(err, ErrSpecific) {
        logger.Errorf("known issue: %v", err)
    }
    return fmt.Errorf("fn: %w", err)
}

// BAD — switch duplicates return, widens scope
err := fn()
switch {
case errors.Is(err, ErrSpecific):
    logger.Errorf("known issue: %v", err)
    return fmt.Errorf("fn: %w", err)
case err != nil:
    return fmt.Errorf("fn: %w", err)
}
```

**GP-3. Errors are sentinels.** Always `var errX = errors.New(...)` by default — checkable via `errors.Is`, usable in tests. Inline `errors.New` only if genuinely one-off. Errors are domain models — live in domain package.

```go
// BAD — not checkable, not testable
return errors.New("order not found")

// GOOD
var errOrderNotFound = errors.New("order not found")  // unexported
var ErrOrderNotFound = errors.New("order not found")  // exported, cross-package
```

**GP-4. Wrap = stacktrace.** Every error from function/method MUST be wrapped with callee name.

**GP-7. Every code change MUST have an obvious reason.** Do not introduce changes that have no clear purpose — no dead assignments, no split-then-rejoin chains, no no-op transformations.

```go
return fmt.Errorf("parseConfig: %w", err)      // function
return fmt.Errorf("validate: %w", err)          // own method
return fmt.Errorf("repo.Save: %w", err)         // instance.Method
return fmt.Errorf("json.Unmarshal: %w", err)    // package.Func
return fmt.Errorf("repo.Get: bucket %d: %w", bucket, err)  // with context
```

```go
// GOOD — nested wrapping builds trace: "DoTx: create: repo.Save: connection refused"
if err := r.DoTx(ctx, bucket, func(ctx context.Context) error {
    if err := r.create(ctx, v); err != nil {
        return fmt.Errorf("create: %w", err)
    }
    return nil
}); err != nil {
    return fmt.Errorf("DoTx: %w", err)
}
```

Skip wrapping: local closures, single obvious call site.

**GP-5. Scope drives naming.** Short life = short name. Long life = descriptive name. Position in function signals lifetime.

```go
// BAD — verbose in tight scope
for index, element := range items {
    processElement(element)
}

// GOOD — short names, context is clear
for i, v := range items {
    process(v)
}
```

</IMPORTANT>

## Scope & Naming

**SN-1. Receivers and closures.** `x` for struct methods, `r` for repo, `v` for closures/lambdas.

```go
func (x *Service) Process(ctx context.Context) error { ... }
func (r *Repo) Find(ctx context.Context) error { ... }
lo.Map(items, func(v Item, _ int) string { return v.Name })
```

**SN-2. Context-aware names.** Package and type provide context — use them to keep names short.

```go
// BAD — type name stutters with package: order.OrderService
package order
type OrderService struct { ... }

// GOOD — package is context: order.Service
package order
type Service struct { ... }
```

When a package has multiple operations, method and model names SHOULD include the domain noun:

```go
// GOOD — distinguishes operations within same package
func (x *Service) CreateOrder(req CreateOrderRequest) (*CreateOrderResult, error)
func (x *Service) CancelOrder(req CancelOrderRequest) (*CancelOrderResult, error)
```

**SN-3. Variable grouping.** 3+ variables → `var(...)` block. Aligns visually, signals "these belong together".

```go
// BAD — scattered
groupKey := gofakeit.UUID()
now := time.Now()
releaseNop := func(_ context.Context) {}

// GOOD
var (
    groupKey   = gofakeit.UUID()
    now        = time.Now()
    releaseNop = func(_ context.Context) {}
)
```

**SN-4. Position signals scope.** Variables communicate lifetime through position. `var res Result` at function top → reader knows it lives through entire function. `:=` deep in a block → reader knows it's temporary. This positional signal replaces comments.

- **Return values** → `var res T` at function top
- **Long-lived intermediates** → declare before the block where consumed. Earlier = wider scope
- **Short-lived** → `:=` at use site. Used in 2-3 lines? Declare right there

```go
func (x *Service) Process(ctx context.Context, id string) (Result, error) {
    var res Result  // returned — declared at top, signals lifetime

    data, err := x.repo.Get(ctx, id)  // short-lived — at use site
    if err != nil {
        return res, fmt.Errorf("repo.Get: %w", err)
    }

    res.Name = data.Name
    res.Status = computeStatus(data)

    return res, nil
}
```

**SN-5. Code clustering.** Functions tell a story: fetch → transform → persist. Each step is a cluster of tightly related lines. Blank lines between clusters = paragraph breaks. Within a cluster, no blank lines — the lines are one thought.

Pattern: `fetch + guard` → blank → `transform` → blank → `persist + guard`

```go
tx, err := x.repo.Get(ctx, id)
if err != nil {
    return fmt.Errorf("repo.Get: %w", err)
}

tx.Status = StatusProcessed
tx.ProcessedAt = lo.ToPtr(time.Now())

if err = x.repo.Update(ctx, tx); err != nil {
    return fmt.Errorf("repo.Update: %w", err)
}
```

## Layout

**LY-1. File order.** Type + constructor → exported methods → unexported methods. Within group: callers before callees.

```go
type Service struct { ... }              // 1. type
func New(...) *Service { ... }           // 2. constructor
func (x *Service) Process(...) { ... }   // 3. exported (caller)
func (x *Service) Get(...) { ... }       // 4. exported
func (x *Service) validate(...) { ... }  // 5. unexported (callee of Process)
func (x *Service) transform(...) { ... } // 6. unexported (callee of validate)
```

**LY-2. Struct + dependency interfaces in one `type(...)` block.** Main struct first, dependency interfaces after. Interfaces sorted by abstraction level: primitive → infrastructure → business. All in root package file (e.g., `usecases.go`, `service.go`).

```go
// BAD — dependencies before the thing that uses them
type (
    repo interface {
        Save(ctx context.Context, v Model) error
    }

    Service struct {
        repo  repo
        queue queue
    }
)

// GOOD — struct first, interfaces after, sorted by abstraction
type (
    Service struct {
        clock  clock
        txMgr  txMgr
        repo   repo
    }

    clock interface { NowUTC() time.Time }               // primitive
    txMgr interface { Do(ctx context.Context, ...) error } // infrastructure
    repo  interface { Save(ctx context.Context, v Model) error } // business
)
```

**LY-3. Struct field sorting.** Generic/primitive first, specific/business last. Same order as interfaces.

```go
// BAD
type Handler struct {
    repo    Repo
    logger  *slog.Logger
    handler EventHandler
    clock   Clock
}

// GOOD
type Handler struct {
    clock   Clock
    logger  *slog.Logger
    repo    Repo
    handler EventHandler
}
```

**LY-4. Layer boundaries.** Domain and model packages NEVER contain infrastructure knowledge — raw SQL, column names, JSONB paths, type casts (`::INT`), table references. Infrastructure logic ALWAYS lives in adapter packages.

## Errors

**ERR-3. `errorsx.Is[T]` over `errors.As`.** Check if your project has an `errorsx` or similar typed-errors package. Type parameter = pointer type (because only `*T` implements `error`).

```go
// BAD
var derr *derrors.Error
if errors.As(err, &derr) { ... }

// GOOD
if derr, ok := errorsx.Is[*derrors.Error](err); ok { ... }
```

## Style

**STY-1. One item per line.** When line exceeds ~120 chars OR args/fields > 3 — split to one per line.

```go
// OK — fits in 120 chars
result, err := repo.Find(ctx, bucket, filter)

// GOOD — exceeds 120 chars or 4+ args, split
result, err := repo.Find(ctx,
    bucket,
    filter,
    limit,
    offset,
)
```

**STY-2. Multi-field struct init.** >2 fields → each on own line.

```go
// BAD
req := Request{ID: id, Name: name, Status: status}

// GOOD
req := Request{
    ID:     id,
    Name:   name,
    Status: status,
}
```

**STY-3. Comments: zero by default.** Only `// WHY:` when non-obvious after better naming.

```go
// BAD — restates code
// save the transaction
repo.Save(ctx, tx)

// GOOD — WHY when non-obvious
// WHY: DB time, not app time — clock skew
deletedBefore := sq.Expr("now() - interval '30 days'")
```

**STY-4. Abbreviations.** Standard only: `ctx`, `cfg`, `req`, `resp`, `tx`, `err`, `res`. `any` over `interface{}`.

## Modern Go

**MG-1. `cmp.Or` for defaults** (1.22+). First non-zero value — simple fallback chains.

```go
// BAD
name := cfg.Name
if name == "" {
    name = "default"
}

// GOOD
name := cmp.Or(cfg.Name, env.Name, "default")
```

When NOT to use: side effects in arguments, complex expressions, non-comparable types.

**MG-2. `omitzero` for JSON** (1.24+). Use for `time.Time`, `time.Duration`, structs, slices, maps. `omitempty` treats these as non-empty at zero value.

**MG-3. `wg.Go()`** (1.25+). Always `wg.Go(func() { ... })` instead of `wg.Add(1)` + `go func() { defer wg.Done(); ... }()`.

## samber/lo

Use `lo` to replace boilerplate. Lambda body > 3 lines or nested `lo` calls → write plain Go.

| Pattern | lo | Replaces |
|---------|----|----------|
| Value → pointer | `lo.ToPtr(val)` | `x := val; &x` |
| Pointer → value | `lo.FromPtr(ptr)` | `if ptr != nil { *ptr }` |
| Transform slice | `lo.Map(items, func(v A, _ int) B { ... })` | for + append |
| Conditional | `lo.Ternary(cond, a, b)` | if/else assignment |
| Unwrap or panic | `lo.Must(fn())` | val + err + panic |
| Filter | `lo.Filter(items, func(v T, _ int) bool { ... })` | for + if + append |
| Deduplicate | `lo.Uniq(items)` | map + loop |

Lambda naming: `v` for value, `_` for unused index.

## Project-Specific

**PS-1. genuuid ↔ uuid casts.** Direct type cast in DTO files, no parse functions.

```go
ID: genuuid.UUID(row.ID)   // DB → domain (scan)
ID: uuid.UUID(model.ID)    // domain → DB (insert)
```

**PS-2. Transaction body compact.** Build ALL models and tasks BEFORE `txmanager.Do`. Lambda = only repo/queue calls.

```go
// GOOD — everything built before, lambda is compact
tx := buildTransaction(req, bucket)
task := tasks.NewCreateTask(req.ID, req.ProductType)

if err = txManager.Do(ctx, bucket, func(ctx context.Context) error {
    if err = repo.Create(ctx, bucket, tx); err != nil {
        return fmt.Errorf("repo.Create: %w", err)
    }
    if err = queue.PushTask(ctx, bucket, task); err != nil {
        return fmt.Errorf("queue.PushTask: %w", err)
    }
    return nil
}); err != nil {
    return fmt.Errorf("txManager.Do: %w", err)
}
```

**PS-3. Errgroup wrappers.** For error propagation use project errgroup wrapper (if available), not raw `sync.WaitGroup`. Check project imports for errgroup packages. Pattern: `eg.Go(func() error { ... })`, `eg.Wait()`.

**PS-4. Config access.** Use project config library for typed config access. Look at neighboring config methods for the pattern — follow existing conventions.

<IMPORTANT>

## Anchor — Most Violated

- **GP-2** Bare switch for classification — not if-else chains
- **GP-4** Wrap errors with callee name — `fmt.Errorf("callee: %w", err)`
- **GP-3** Sentinel errors by default — `var errX = errors.New(...)`
- **SN-3** 3+ variables → `var(...)` block
- **STY-1** Line > 120 chars or > 3 args → one per line

</IMPORTANT>
