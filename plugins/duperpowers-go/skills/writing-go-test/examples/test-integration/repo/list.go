package order_repo

import (
	"context"
	"fmt"

	"orders/internal/domain/models"
)

func (r *Repo) List(ctx context.Context) ([]models.Order, error) {
	b := r.db.Builder().
		Select("*").
		From(tableName).
		OrderBy("created_at")

	var rows []models.Order
	if err := r.db.Selectx(ctx, &rows, b); err != nil {
		return nil, fmt.Errorf("selectx: %w", err)
	}

	return rows, nil
}
