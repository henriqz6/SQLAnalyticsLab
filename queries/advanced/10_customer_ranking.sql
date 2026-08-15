-- Problema: criar ranking de clientes por valor sem perder empates e participação acumulada.
-- Solução: DENSE_RANK ordena por LTV e a janela acumulada permite segmentação Pareto.
WITH customer_value AS (
  SELECT
    customer_id,
    full_name,
    valid_order_count,
    lifetime_value,
    average_ticket,
    last_order_at
  FROM v_customer_360
  WHERE valid_order_count > 0
), ranked AS (
  SELECT
    cv.*,
    DENSE_RANK() OVER (ORDER BY lifetime_value DESC) AS value_rank,
    SUM(lifetime_value) OVER (ORDER BY lifetime_value DESC, customer_id) AS cumulative_value,
    SUM(lifetime_value) OVER () AS total_value
  FROM customer_value cv
)
SELECT
  customer_id,
  full_name,
  valid_order_count,
  ROUND(lifetime_value, 2) AS lifetime_value,
  ROUND(average_ticket, 2) AS average_ticket,
  last_order_at,
  value_rank,
  ROUND(100 * cumulative_value / NULLIF(total_value, 0), 2) AS cumulative_revenue_percent,
  CASE
    WHEN cumulative_value / NULLIF(total_value, 0) <= 0.80 THEN 'A'
    WHEN cumulative_value / NULLIF(total_value, 0) <= 0.95 THEN 'B'
    ELSE 'C'
  END AS customer_curve
FROM ranked
ORDER BY value_rank, customer_id;
