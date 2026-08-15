-- Problema: acompanhar cancelamento e devolução mensal sem misturar denominadores.
-- Solução: CTEs agregam pedidos e devoluções antes da junção por mês.
WITH monthly_orders AS (
  SELECT
    DATE_FORMAT(placed_at, '%Y-%m-01') AS month_start,
    COUNT(*) AS orders_created,
    SUM(status = 'CANCELLED') AS cancelled_orders,
    SUM(status = 'DELIVERED') AS delivered_orders
  FROM orders
  GROUP BY DATE_FORMAT(placed_at, '%Y-%m-01')
), monthly_returns AS (
  SELECT
    DATE_FORMAT(o.placed_at, '%Y-%m-01') AS month_start,
    COUNT(DISTINCT r.return_id) AS returned_orders
  FROM returns r
  JOIN orders o ON o.order_id = r.order_id
  WHERE r.status IN ('RECEIVED','REFUNDED')
  GROUP BY DATE_FORMAT(o.placed_at, '%Y-%m-01')
)
SELECT
  mo.month_start,
  mo.orders_created,
  mo.cancelled_orders,
  ROUND(100 * mo.cancelled_orders / NULLIF(mo.orders_created, 0), 2) AS cancellation_rate_percent,
  mo.delivered_orders,
  COALESCE(mr.returned_orders, 0) AS returned_orders,
  ROUND(100 * COALESCE(mr.returned_orders, 0) / NULLIF(mo.delivered_orders, 0), 2) AS return_rate_percent
FROM monthly_orders mo
LEFT JOIN monthly_returns mr ON mr.month_start = mo.month_start
ORDER BY mo.month_start;
