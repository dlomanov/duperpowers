//go:build unit

package order_usecases

import (
	"testing"
	"time"

	"github.com/brianvoe/gofakeit/v7"
	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"

	"orders/internal/adapters/postgres/txmanager"
	"orders/internal/domain/models"
	"orders/internal/domain/tasks"
)

func TestUseCases_Create(t *testing.T) {
	t.Parallel()

	var (
		order = models.Order{
			ID:         uuid.New(),
			CustomerID: uuid.New(),
			Total:      gofakeit.Int64(),
			Status:     models.OrderStatusNew,
			CreatedAt:  gofakeit.Date().UTC().Truncate(time.Microsecond),
		}
		req = CreateOrderReq{
			ID:         order.ID,
			CustomerID: order.CustomerID,
			Total:      order.Total,
		}
	)

	type args = CreateOrderReq

	tests := []struct {
		name    string
		args    args
		before  func(args args, m mockList)
		want    models.Order
		wantErr error
	}{
		// existing-check fails - propagate error from repo
		{
			name: "find error",
			args: req,
			before: func(_ args, m mockList) {
				m.orderRepo.EXPECT().
					Find(mock.Anything, mock.Anything).
					Return(nil, assert.AnError).
					Once()
			},
			wantErr: assert.AnError,
		},
		// idempotent: order already exists - return without creating
		{
			name: "already created",
			args: req,
			before: func(_ args, m mockList) {
				m.orderRepo.EXPECT().
					Find(mock.Anything, mock.Anything).
					Return(&order, nil).
					Once()
			},
			want: order,
		},
		// tx step 1 fails - error bubbles up from txManager
		{
			name: "create error",
			args: req,
			before: func(_ args, m mockList) {
				m.orderRepo.EXPECT().
					Find(mock.Anything, mock.Anything).
					Return(nil, nil).
					Once()
				m.timer.EXPECT().
					NowUTC().
					Return(order.CreatedAt).
					Once()
				m.txManager.EXPECT().
					Do(mock.Anything, mock.Anything).
					RunAndReturn(txmanager.MockCallbackExecutor).
					Once()
				m.orderRepo.EXPECT().
					Create(mock.Anything, mock.Anything).
					Return(assert.AnError).
					Once()
			},
			wantErr: assert.AnError,
		},
		// tx step 2 fails - error bubbles up from txManager
		{
			name: "push task error",
			args: req,
			before: func(_ args, m mockList) {
				m.orderRepo.EXPECT().
					Find(mock.Anything, mock.Anything).
					Return(nil, nil).
					Once()
				m.timer.EXPECT().
					NowUTC().
					Return(order.CreatedAt).
					Once()
				m.txManager.EXPECT().
					Do(mock.Anything, mock.Anything).
					RunAndReturn(txmanager.MockCallbackExecutor).
					Once()
				m.orderRepo.EXPECT().
					Create(mock.Anything, mock.Anything).
					Return(nil).
					Once()
				m.queue.EXPECT().
					PushTask(mock.Anything, mock.Anything).
					Return(assert.AnError).
					Once()
			},
			wantErr: assert.AnError,
		},
		// happy path: create order in tx + publish kafka task
		{
			name: "success",
			args: req,
			before: func(args args, m mockList) {
				m.orderRepo.EXPECT().
					Find(mock.Anything, args.ID).
					Return(nil, nil).
					Once()
				m.timer.EXPECT().
					NowUTC().
					Return(order.CreatedAt).
					Once()
				m.txManager.EXPECT().
					Do(mock.Anything, mock.Anything).
					RunAndReturn(txmanager.MockCallbackExecutor).
					Once()
				m.orderRepo.EXPECT().
					Create(mock.Anything, order).
					Return(nil).
					Once()
				m.queue.EXPECT().
					PushTask(mock.Anything, tasks.NewTaskOrderPublish(order.ID)).
					Return(nil).
					Once()
			},
			want: order,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			sut, m := makeSUT(t)
			if tt.before != nil {
				tt.before(tt.args, m)
			}

			got, err := sut.Create(t.Context(), tt.args)

			assert.Equal(t, tt.want, got)
			assert.ErrorIs(t, err, tt.wantErr)
		})
	}
}
