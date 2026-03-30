---
name: go-writer-test
description: "Project Go test conventions for *_test.go files. MUST invoke for any Go test task."
---

# Go Unit Tests

<IMPORTANT>

## Golden Rules

Non-negotiable. If test code matches BAD — fix it.

**TG-1. Read existing tests first.** Before writing tests, read ALL `*_test.go` in the package. Identify shared `mockList`, `makeMocks`, `before` patterns, assertion style. Always reuse existing infrastructure.

**TG-2. AAA structure.** Arrange / Act / Assert separated by one blank line. No section markers.

```go
// BAD — markers are noise
// Arrange
sut, m := makeSUT(t)
// Act
got, err := sut.Method(t.Context())
// Assert
assert.NoError(t, err)

// GOOD — blank lines are enough
sut, m := makeSUT(t)

got, err := sut.Method(t.Context())

assert.NoError(t, err)
```

**TG-3. Error assertions.** Always `assert.ErrorIs(t, err, tt.wantErr)` — handles nil and non-nil uniformly. Always `assert.AnError` for "any error" — never `var errTest = errors.New(...)`.

```go
// BAD
if tt.wantErr != nil { require.ErrorIs(t, err, tt.wantErr) } else { require.NoError(t, err) }

// GOOD — one line, both cases
assert.ErrorIs(t, err, tt.wantErr)
```

```go
// BAD
var errTest = errors.New("test error")
wantErr: errTest,

// GOOD
wantErr: assert.AnError,         // any error
wantErr: domain.ErrNotFound,     // specific production sentinel
```

**TG-4. Case order: simple → complex → success LAST.** Reader sees "what can go wrong" before "what goes right". Compose `success` first (with concrete mock values), then derive failure cases from it.

```go
// пустая строка не должна дойти до репозитория
{
    name:    "empty input",
    wantErr: ErrEmpty,
},
// ошибка репозитория прокидывается наверх
{
    name: "repo error",
    before: func(m mockList) {
        m.repo.EXPECT().
            Get(mock.Anything).
            Return(nil, assert.AnError).
            Once()
    },
    wantErr: assert.AnError,
},
// все зависимости отработали – результат собран
{
    name: "success",
    args: id,
    before: func(a args, m mockList) {
        m.repo.EXPECT().
            Get(a).
            Return(expected, nil).
            Once()
    },
    want: expected,
},
```

**TG-5. Mock arg specificity.** Only `success` case passes concrete values to mocks — verifies correct parameter threading. All other cases use `mock.Anything` for params irrelevant to the tested behavior.

```go
// BAD — concrete values duplicated in failure case
m.repo.EXPECT().
    List(mock.Anything, bucket, groupKey, batchSize).
    Return(nil, assert.AnError).
    Once()

// GOOD — only mock.Anything in failure cases, concrete in success
m.repo.EXPECT().
    List(mock.Anything, mock.Anything, mock.Anything, mock.Anything).
    Return(nil, assert.AnError).
    Once()
```

</IMPORTANT>

## Structure

**TS-1. Parallel + Context.** `t.Parallel()` in parent AND each `t.Run()`. Blank line after. Always `t.Context()` for context.

```go
func TestService_Create(t *testing.T) {
    t.Parallel()

    // ...
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()

            // use t.Context() for ctx
        })
    }
}
```

**TS-2. Naming.** `TestFunc` for package-level functions, `Test_privateFunc` for private, `TestType_Method` for methods. Same package as target (whitebox, no `_test` suffix).

**TS-3. File order.** Test functions → `type mockList struct` → `makeMocks()` / `makeSUT()`.

## Table Tests

**TT-1. Table only for 2+ cases.** Single case = simple test, no table. Case names use spaces: `"lock busy"`, `"empty result"`. Happy path: `"success"`, never `"happy_path"`.

**TT-2. Struct shape + field order.** Fields: `name`, `args`, `before`, `want`/`wantErr`. Flat when ≤4 fields. Group into `args`/`wants` sub-structs when 5+. Always multi-line struct literals.

**TT-3. `before` = mock setup ONLY.** Signature: `func(args args, m mockList)`. Without args: `func(m mockList)`. Omit field when no setup needed — `if tt.before != nil` guard handles nil.

**TT-4. Case comments.** Russian comment above each case on WHY it matters — what behavior or invariant it guards. Add value beyond case name.

```go
// BAD — restates name
// пустой ввод
{
    name:    "empty input",
    wantErr: ErrEmpty,
},

// GOOD — explains WHY
// пустая строка не должна дойти до репозитория, отсекаем на входе
{
    name:    "empty input",
    wantErr: ErrEmpty,
},
```

**TT-5. Always multi-line struct literals.** Every case — each field on its own line.

```go
// BAD — compact one-liner
{name: "empty input", wantErr: ErrEmpty},

// GOOD — always expanded
{
    name:    "empty input",
    wantErr: ErrEmpty,
},
```

**TT-6. Spell out zero-value wants.** Omission signals "not under test", not "expect zero". Exception: `wantErr` nil omission is idiomatic.

```go
// BAD — reader assumes want is irrelevant
{
    name:        "disabled",
    productType: tip,
},

// GOOD — zero value is the assertion
{
    name:        "disabled",
    productType: tip,
    want:        false,
},
```

**TT-7. `wantErr error` type.** Always `error`, never `bool`.

## Mocks

**TM-1. mockList + makeMocks + makeSUT.** Generated mocks only (mockery). All mocks as pointers in struct.

```go
type mockList struct {
    repo  *mocks.Repo
    cache *mocks.Cache
}

func makeMocks(t *testing.T) mockList {
    return mockList{
        repo:  mocks.NewRepo(t),
        cache: mocks.NewCache(t),
    }
}
```

Single SUT in package → `func makeSUT(t *testing.T) (*Service, mockList)` at file end. Multiple SUTs → inline creation, reuse `makeMocks(t)`.

**TM-3. No `t.Helper()` in `makeSUT`/`makeService`/`makeMocks`.** These functions create mocks and construct SUT — never add `t.Helper()`.

```go
// BAD — t.Helper() in makeSUT
func makeSUT(t *testing.T) (*Service, mockList) {
    t.Helper()

    m := mockList{
        repo: mocks.NewRepo(t),
    }

    return New(m.repo), m
}

// GOOD — no t.Helper()
func makeSUT(t *testing.T) (*Service, mockList) {
    m := mockList{
        repo: mocks.NewRepo(t),
    }

    return New(m.repo), m
}
```

**TM-2. Mock chain: one method per line.** Break after `EXPECT().`:

```go
// BAD
m.locker.EXPECT().Acquire(mock.Anything, bucket, lockKey(groupKey)).
    Return(releaseNop, nil).Once()

// GOOD
m.locker.EXPECT().
    Acquire(mock.Anything, bucket, lockKey(groupKey)).
    Return(releaseNop, nil).
    Once()
```

## Data

**TD-1. Test data.** gofakeit for pass-through values the code doesn't validate. Realistic hardcoded values for anything that affects behavior.

```go
// BAD — random duration obscures intent, random enum is meaningless
{
    name: "timeout",
    args: args{
        ttl:    time.Duration(gofakeit.Int64()),
        status: transactions.Status(gofakeit.Int32()),
    },
},

// GOOD — hardcoded for behavior, random for pass-through
{
    name: "timeout",
    args: args{
        ttl:    200 * time.Millisecond,
        status: transactions.Status_STATUS_CREATED,
        key:    gofakeit.UUID(),
    },
},
```

| Use | gofakeit | Hardcoded |
|-----|----------|-----------|
| IDs, keys, names | `gofakeit.UUID()`, `gofakeit.Word()` | — |
| Enums, statuses | — | `Status_STATUS_CREATED` |
| Durations, timeouts | — | `200 * time.Millisecond` |
| Amounts | `testx.CreateMoney()` | — |
| Counters, indices | — | `int64(1)`, `int64(2)` |

**TD-2. Shared values.** Values shared across cases → `var(...)` block before table (see duperpowers-go:go-writer SN-3). Infrastructure constants (e.g., `bucket`) → package-level `const`. Each case shows only what VARIES.

```go
// BAD — duplicated literals
{
    name:    "not found",
    args:    "user-123",
    wantErr: ErrNotFound,
},
{
    name: "success",
    args: "user-123",
    want: User{ID: "user-123"},
},

// GOOD — shared value extracted
id := gofakeit.UUID()
// ...
{
    name:    "not found",
    args:    id,
    wantErr: ErrNotFound,
},
{
    name: "success",
    args: id,
    want: User{ID: id},
},
```

## Advanced

**TA-1. Goroutine sync.** When SUT spawns goroutines, wrap test body in `synctest.Test`. Call `synctest.Wait()` after Act.

```go
synctest.Test(t, func(t *testing.T) {
    sut, m := makeSUT(t)
    if tt.before != nil {
        tt.before(m)
    }

    resp, err := sut.Method(t.Context(), args)
    synctest.Wait()

    assert.NoError(t, err)
})
```

**TA-2. Integration tests.** Look at reference integration test in the same repo layer for patterns. Structure:

```go
// package-level setup
var testCluster *cluster.Cluster

func TestMain(m *testing.M) {
    secrets, configs := config.LoadTestEnv()

    var err error
    testCluster, err = cluster.New(context.Background(), secrets, configs)
    if err != nil {
        panic(err)
    }
    defer testCluster.Close()

    m.Run()
}
```

```go
// makeSUT — real DB, mock only clock/external
func makeSUT(t *testing.T) (*Repo, mockList) {
    m := mockList{timer: mocks.NewTimer(t)}
    m.timer.EXPECT().NowUTC().Return(testTime).Maybe()

    return New(repo.NewBaseRepo(testCluster), m.timer), m
}
```

```go
// TestRepo — test group with shared setup
func TestRepo(t *testing.T) {
    t.Parallel()

    sut, _ := makeSUT(t)
    a := assert.New(t)
    ctx := context.Background()

    // Create
    err := sut.Create(ctx, bucketNumber, entity)
    a.NoError(err)

    // Find
    actual, err := sut.Find(ctx, bucketNumber, filter)
    a.NoError(err)
    a.Equal(entity.ID, actual.ID)
}
```

```go
// TestRepo_Method — table-driven with rollback isolation
func TestRepo_Method(t *testing.T) {
    t.Parallel()

    sut, _ := makeSUT(t)

    tests := []struct {
        name   string
        action func(ctx context.Context, a *assert.Assertions)
    }{
        // ...
    }
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            t.Parallel()

            a := assert.New(t)
            err := sut.WithTx(t.Context(), bucketNumber, func(ctx context.Context) error {
                tt.action(ctx, a)
                return errRollback
            })
            a.ErrorIs(err, errRollback)
        })
    }
}
```

## Template

File order: test functions → `type mockList struct` → `makeMocks()` / `makeSUT()`.

```go
func TestService_Method(t *testing.T) {
	t.Parallel()

	var (
		id       = gofakeit.UUID()
		expected = ResultType{ID: id}
	)

	type args = string
	tests := []struct {
		name    string
		args    args
		before  func(args args, m mockList)
		want    ResultType
		wantErr error
	}{
		// пустая строка не должна дойти до репозитория, отсекаем на входе
		{
			name:    "empty input",
			wantErr: ErrEmpty,
		},
		// ошибка репозитория прокидывается наверх без оборачивания
		{
			name: "dependency fails",
			before: func(_ args, m mockList) {
				m.repo.EXPECT().
					Get(mock.Anything).
					Return(nil, assert.AnError).
					Once()
			},
			wantErr: assert.AnError,
		},
		// все зависимости отработали – возвращаем собранный результат
		{
			name: "success",
			args: id,
			before: func(a args, m mockList) {
				m.repo.EXPECT().
					Get(a).
					Return(expected, nil).
					Once()
			},
			want: expected,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			sut, m := makeSUT(t)
			if tt.before != nil {
				tt.before(tt.args, m)
			}

			got, err := sut.Method(t.Context(), tt.args)

			assert.Equal(t, tt.want, got)
			assert.ErrorIs(t, err, tt.wantErr)
		})
	}
}
```

**Variants** (delta from template):
- **Without mocks:** Remove `before`, `makeSUT`. Call `FuncName(t.Context(), tt.args)` directly.
- **Without args:** Remove `args` field/type. `before` signature: `func(m mockList)`.
- **Returns only error:** Remove `want` and `assert.Equal` line.

<IMPORTANT>

## Anchor — Most Violated

- **TG-3** `assert.ErrorIs` + `assert.AnError` — never if/else, never `var errTest`
- **TG-4** Case order: simple → complex → success LAST
- **TG-5** Mock specificity: success = concrete, failures = `mock.Anything`
- **TM-2** Mock chain: break after `EXPECT().`, one method per line
- **TT-5** Always multi-line struct literals — never compact one-liners

</IMPORTANT>
