-- Problema: comparar vendas e devoluções sem multiplicar linhas por joins 1:N.
-- Solução: vendas e devoluções são agregadas separadamente e unidas pelo produto.
WITH sales AS (
  SELECT
    oi.product_id,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.line_total) AS item_revenue
  FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  WHERE o.status <> 'CANCELLED'
  GROUP BY oi.product_id
), returned AS (
  SELECT
    oi.product_id,
    SUM(ri.quantity) AS units_returned,
    SUM(ri.refund_amount) AS refunded_amount
  FROM return_items ri
  JOIN returns r ON r.return_id = ri.return_id AND r.status IN ('RECEIVED','REFUNDED')
  JOIN order_items oi ON oi.order_item_id = ri.order_item_id
  GROUP BY oi.product_id
)
SELECT
  p.sku,
  p.name,
  COALESCE(s.units_sold, 0) AS units_sold,
  COALESCE(r.units_returned, 0) AS units_returned,
  ROUND(100 * COALESCE(r.units_returned, 0) / NULLIF(s.units_sold, 0), 2) AS return_rate_percent,
  ROUND(COALESCE(s.item_revenue, 0), 2) AS item_revenue,
  ROUND(COALESCE(r.refunded_amount, 0), 2) AS refunded_amount
FROM products p
LEFT JOIN sales s ON s.product_id = p.product_id
LEFT JOIN returned r ON r.product_id = p.product_id
ORDER BY units_sold DESC, units_returned DESC
LIMIT 30;
