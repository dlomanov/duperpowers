---
name: go-writer-test
description: "Project Go test conventions for *_test.go files. MUST invoke for any Go test task."
---

# Go Unit Tests

Unit tests here are **white-box**: lock coverage, fix degrees of freedom, verify field propagation. They do NOT prove behavior — that is the job of integration / acceptance tests. Cases map to **behaviors** (branches, validations, error paths), NEVER to fields. Adding a propagated field ≠ adding a case.

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

**TG-6. One case per behavior, not per field.** A test case encodes a behavior: a branch, a validation, an error path. A newly propagated field **extends the existing `success` case** — update the shared `expected` and the mock `Return`, done. Add a new case ONLY when the field introduces new behavior: a new branch, own validation, or a new error sentinel.

```go
// BAD — добавили Tags, создали новый кейс, продублировали все зависимости
{
    name: "success",
    args: id,
    before: func(a args, m mockList) {
        m.repo.EXPECT().
            Get(a).
            Return(User{ID: id}, nil).
            Once()
    },
    want: User{ID: id},
},
{
    name: "success with tags",
    args: id,
    before: func(a args, m mockList) {
        m.repo.EXPECT().
            Get(a).
            Return(User{ID: id, Tags: []string{"go"}}, nil).
            Once()
    },
    want: User{ID: id, Tags: []string{"go"}},
},

// GOOD — расширили expected у существующего success
var (
    id       = gofakeit.UUID()
    expected = User{ID: id, Tags: []string{"go"}} // ← новое поле прилетает сюда
)
// ...
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

| Rationalization | Reality |
|---|---|
| "Новое поле — нагляднее отдельным кейсом" | Кейс = поведение, а не поле. Propagation идёт в `expected`. |
| "Добавлю кейс, чтобы явно показать поле" | Поле уже видно в `expected`. Новый кейс = дубль моков + шум. |
| "Это тоже success, просто с полем" | Success один. Расширь его. |
| "Вдруг кто-то захочет смотреть только это поле" | Для этого есть `assert.Equal` по структуре — composite assertion. |

Triggers that DO justify a new case (a new *behavior* appears with the field):
- field switches a branch: `if u.Deleted { ... }` → нужны кейсы `deleted` и `active`
- field has its own validation: `if u.Email == "" { return ErrNoEmail }` → нужен кейс `empty email`
- field unlocks a new error path from a dep: новая ветка `repo.Get` возвращает `ErrExpired`

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

**TM-3. No `t.Helper()` in `makeSUT`/`makeMocks`.** These create mocks and construct SUT — unconditional, never helpers.

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

**TF-1. Test data.** gofakeit for pass-through values the code doesn't validate. Realistic hardcoded values for anything that affects behavior.

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

**TF-2. Shared values.** Values shared across cases → `var(...)` block before table (see duperpowers-go:go-writer SN-3). Infrastructure constants (e.g., `bucket`) → package-level `const`. Each case shows only what VARIES.

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

**TA-2. Integration tests.** Read existing integration tests in the same repo layer for patterns (`TestMain`, `makeSUT` with real DB, rollback isolation). Ask user for reference file if none found.

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
- **TG-6** One case per behavior, not per field — new propagated field extends `success`, never creates a case
- **TM-2** Mock chain: break after `EXPECT().`, one method per line
- **TT-5** Always multi-line struct literals — never compact one-liners

</IMPORTANT>
