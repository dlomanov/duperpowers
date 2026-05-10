//go:build integration

package order_repo

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/brianvoe/gofakeit/v7"
	"github.com/google/uuid"
	"github.com/samber/lo"
	"github.com/stretchr/testify/assert"

	"orders/internal/adapters/postgres"
	"orders/internal/adapters/postgres/order_repo/mocks"
	"orders/internal/config"
	"orders/internal/domain/models"
)

var (
	errRollback = errors.New("rollback error")
	testTime    = gofakeit.Date().UTC().Truncate(time.Microsecond)
	testDB      *postgres.DB
)

type mockList struct {
	timer *mocks.Timer
}

func makeSUT(t *testing.T) (*Repo, mockList) {
	m := mockList{
		timer: mocks.NewTimer(t),
	}
	m.timer.EXPECT().NowUTC().Return(testTime).Maybe()

	return New(testDB, m.timer), m
}

func TestMain(m *testing.M) {
	var err error

	testDB, err = postgres.New(context.Background(), config.LoadTestEnv())
	if err != nil {
		panic(err)
	}
	defer testDB.Close()

	m.Run()
}

func TestRepo(t *testing.T) {
	t.Parallel()

	sut, _ := makeSUT(t)

	tests := []struct {
		name   string
		action func(ctx context.Context, a *assert.Assertions)
	}{
		// happy path: create 3 -> update 1 -> list returns all 3 in created_at order
		{
			name: "success",
			action: func(ctx context.Context, a *assert.Assertions) {
				orders := make([]models.Order, 3)
				for i := range orders {
					orders[i] = makeOrder()

					a.NoError(sut.Create(ctx, orders[i]))
				}

				orders[1].ProcessedAt = lo.ToPtr(testTime)
				a.NoError(sut.Update(ctx, orders[1].ToUpdater()))

				got, err := sut.List(ctx)
				a.NoError(err)
				a.Len(got, 3)
				a.Equal(orders[0].ID, got[0].ID)
				a.Equal(orders[1].ID, got[1].ID)
				a.Equal(orders[2].ID, got[2].ID)
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			a := assert.New(t)
			err := sut.db.WithTx(t.Context(), func(ctx context.Context) error {
				tt.action(ctx, a)

				return errRollback
			})
			a.ErrorIs(err, errRollback)
		})
	}
}

func makeOrder() models.Order {
	return models.Order{
		ID:         uuid.New(),
		CustomerID: uuid.New(),
		Total:      gofakeit.Int64(),
		Status:     gofakeit.UUID(),
		CreatedAt:  testTime,
		UpdatedAt:  testTime,
	}
}
