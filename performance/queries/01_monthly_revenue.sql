SELECT DATE_FORMAT(placed_at, '%Y-%m-01') AS month_start, SUM(total_amount) AS revenue
FROM orders
WHERE placed_at >= '2025-01-01' AND status IN ('PAID','PROCESSING','SHIPPED','DELIVERED')
GROUP BY DATE_FORMAT(placed_at, '%Y-%m-01')
