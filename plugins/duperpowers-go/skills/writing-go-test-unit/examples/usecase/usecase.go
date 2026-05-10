package order_usecases

import (
	"context"
	"time"

	"github.com/google/uuid"

	"orders/internal/domain/models"
	"orders/internal/domain/tasks"
)

type (
	UseCases struct {
		timer     timer
		txManager txManager
		queue     queue
		orderRepo orderRepo
	}
	timer interface {
		NowUTC() time.Time
	}
	txManager interface {
		Do(ctx context.Context, callback func(ctx context.Context) error) error
	}
	queue interface {
		PushTask(ctx context.Context, t tasks.AnyTask) error
	}
	orderRepo interface {
		Find(ctx context.Context, id uuid.UUID) (*models.Order, error)
		Create(ctx context.Context, v models.Order) error
	}
)

func New(
	timer timer,
	txManager txManager,
	queue queue,
	orderRepo orderRepo,
) *UseCases {
	return &UseCases{
		timer:     timer,
		txManager: txManager,
		queue:     queue,
		orderRepo: orderRepo,
	}
}
