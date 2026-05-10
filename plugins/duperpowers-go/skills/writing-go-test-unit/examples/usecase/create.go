package order_usecases

import (
	"context"
	"fmt"

	"github.com/google/uuid"

	"orders/internal/domain/models"
	"orders/internal/domain/tasks"
)

type CreateOrderReq struct {
	ID         uuid.UUID
	CustomerID uuid.UUID
	Total      int64
}

func (u *UseCases) Create(ctx context.Context, req CreateOrderReq) (models.Order, error) {
	existing, err := u.orderRepo.Find(ctx, req.ID)
	switch {
	case err != nil:
		return models.Order{}, fmt.Errorf("orderRepo.Find: %w", err)
	case existing != nil:
		return *existing, nil
	}

	var (
		order = models.Order{
			ID:         req.ID,
			CustomerID: req.CustomerID,
			Total:      req.Total,
			Status:     models.OrderStatusNew,
			CreatedAt:  u.timer.NowUTC(),
		}
		publishTask = tasks.NewTaskOrderPublish(order.ID)
	)

	if err = u.txManager.Do(ctx, func(ctx context.Context) error {
		if err = u.orderRepo.Create(ctx, order); err != nil {
			return fmt.Errorf("orderRepo.Create: %w", err)
		}

		if err = u.queue.PushTask(ctx, publishTask); err != nil {
			return fmt.Errorf("queue.PushTask: %w", err)
		}

		return nil
	}); err != nil {
		return models.Order{}, fmt.Errorf("txManager.Do: %w", err)
	}

	return order, nil
}
