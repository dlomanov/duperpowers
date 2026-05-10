//go:build integration

package order_repo

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"

	"orders/internal/domain/models"
)

func TestRepo_Create(t *testing.T) {
	t.Parallel()

	sut, _ := makeSUT(t)

	tests := []struct {
		name   string
		action func(ctx context.Context, r *require.Assertions)
	}{
		// canceled context must surface as an error from execx
		{
			name: "execx error",
			action: func(ctx context.Context, r *require.Assertions) {
				ctx, cancel := context.WithCancel(ctx)
				cancel()

				err := sut.Create(ctx, models.Order{})

				r.Error(err)
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			r := require.New(t)
			err := sut.db.WithTx(t.Context(), func(ctx context.Context) error {
				tt.action(ctx, r)

				return errRollback
			})
			r.ErrorIs(err, errRollback)
		})
	}
}
