-- Problema: separar clientes novos e recorrentes em cada mês.
-- Solução: calcula a primeira compra em uma CTE e compara com cada mês ativo.
WITH valid_orders AS (
  SELECT customer_id, order_id, placed_at
  FROM orders
  WHERE status <> 'CANCELLED'
), first_purchase AS (
  SELECT customer_id, MIN(DATE_FORMAT(placed_at, '%Y-%m-01')) AS first_month
  FROM valid_orders
  GROUP BY customer_id
), monthly_customers AS (
  SELECT DISTINCT customer_id, DATE_FORMAT(placed_at, '%Y-%m-01') AS order_month
  FROM valid_orders
)
SELECT
  mc.order_month,
  SUM(mc.order_month = fp.first_month) AS new_customers,
  SUM(mc.order_month > fp.first_month) AS recurring_customers,
  COUNT(*) AS active_customers
FROM monthly_customers mc
JOIN first_purchase fp ON fp.customer_id = mc.customer_id
GROUP BY mc.order_month
ORDER BY mc.order_month;
