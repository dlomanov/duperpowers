package order_repo

import (
	"context"
	"fmt"

	"orders/internal/domain/models"
)

func (r *Repo) Create(ctx context.Context, v models.Order) error {
	b := r.db.Builder().
		Insert(tableName).
		SetMap(map[string]any{
			"id":           v.ID,
			"customer_id":  v.CustomerID,
			"total":        v.Total,
			"status":       v.Status,
			"processed_at": v.ProcessedAt,
			"created_at":   v.CreatedAt,
			"updated_at":   v.UpdatedAt,
		})

	if err := r.db.Execx(ctx, b); err != nil {
		return fmt.Errorf("execx: %w", err)
	}

	return nil
}
