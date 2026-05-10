package order_repo

import (
	"context"
	"time"

	"github.com/Masterminds/squirrel"
)

const tableName = "orders"

type (
	Repo struct {
		timer timer
		db    db
	}
	timer interface {
		NowUTC() time.Time
	}
	db interface {
		Builder() squirrel.StatementBuilderType
		Execx(ctx context.Context, b squirrel.Sqlizer) error
		Selectx(ctx context.Context, dst any, b squirrel.Sqlizer) error
		WithTx(ctx context.Context, fn func(ctx context.Context) error) error
	}
)

func New(db db, timer timer) *Repo {
	return &Repo{
		timer: timer,
		db:    db,
	}
}
