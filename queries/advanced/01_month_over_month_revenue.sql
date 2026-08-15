-- Problema: medir evolução do faturamento sem realizar self join da tabela mensal.
-- Solução: a CTE agrega cada mês e LAG recupera o mês anterior na mesma janela.
WITH monthly AS (
  SELECT
    CAST(DATE_FORMAT(placed_at, '%Y-%m-01') AS DATE) AS month_start,
    SUM(total_amount) AS revenue
  FROM orders
  WHERE status IN ('PAID','PROCESSING','SHIPPED','DELIVERED')
  GROUP BY CAST(DATE_FORMAT(placed_at, '%Y-%m-01') AS DATE)
), compared AS (
  SELECT
    month_start,
    revenue,
    LAG(revenue) OVER (ORDER BY month_start) AS previous_month_revenue,
    LEAD(revenue) OVER (ORDER BY month_start) AS next_month_revenue
  FROM monthly
)
SELECT
  month_start,
  ROUND(revenue, 2) AS revenue,
  ROUND(previous_month_revenue, 2) AS previous_month_revenue,
  ROUND(100 * (revenue - previous_month_revenue) / NULLIF(previous_month_revenue, 0), 2) AS month_over_month_percent,
  ROUND(next_month_revenue, 2) AS next_month_revenue
FROM compared
ORDER BY month_start;
