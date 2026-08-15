SELECT order_id, order_number, status, placed_at, total_amount
FROM orders
WHERE customer_id = 42 AND placed_at >= '2025-01-01'
ORDER BY placed_at DESC
