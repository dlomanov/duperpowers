package order_repo

import (
	"context"
	"fmt"

	"github.com/Masterminds/squirrel"

	"orders/internal/domain/models"
)

func (r *Repo) Update(ctx context.Context, v models.OrderUpdater) error {
	b := r.db.Builder().
		Update(tableName).
		Where(squirrel.Eq{"id": v.ID}).
		SetMap(map[string]any{
			"status":       v.Status,
			"processed_at": v.ProcessedAt,
			"updated_at":   r.timer.NowUTC(),
		})

	if err := r.db.Execx(ctx, b); err != nil {
		return fmt.Errorf("execx: %w", err)
	}

	return nil
}
