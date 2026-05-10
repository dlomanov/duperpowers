//go:build unit

package order_usecases

import (
	"testing"

	"orders/internal/usecases/order_usecases/mocks"
)

type mockList struct {
	timer     *mocks.Timer
	txManager *mocks.TxManager
	queue     *mocks.Queue
	orderRepo *mocks.OrderRepo
}

func makeSUT(t *testing.T) (*UseCases, mockList) {
	m := mockList{
		timer:     mocks.NewTimer(t),
		txManager: mocks.NewTxManager(t),
		queue:     mocks.NewQueue(t),
		orderRepo: mocks.NewOrderRepo(t),
	}

	return New(m.timer, m.txManager, m.queue, m.orderRepo), m
}
