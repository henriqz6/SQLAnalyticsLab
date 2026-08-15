-- Problema: priorizar produtos responsáveis pela maior parte da receita.
-- Solução: soma acumulada por janela classifica produtos nas curvas A/B/C.
WITH product_revenue AS (
  SELECT
    oi.product_id,
    MAX(oi.product_sku) AS sku,
    MAX(oi.product_name) AS product_name,
    SUM(oi.line_total) AS revenue
  FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  WHERE o.status <> 'CANCELLED'
  GROUP BY oi.product_id
), accumulated AS (
  SELECT
    pr.*,
    SUM(revenue) OVER (ORDER BY revenue DESC, product_id) AS cumulative_revenue,
    SUM(revenue) OVER () AS total_revenue
  FROM product_revenue pr
)
SELECT
  product_id,
  sku,
  product_name,
  ROUND(revenue, 2) AS revenue,
  ROUND(100 * cumulative_revenue / total_revenue, 2) AS cumulative_percent,
  CASE
    WHEN cumulative_revenue / total_revenue <= 0.80 THEN 'A'
    WHEN cumulative_revenue / total_revenue <= 0.95 THEN 'B'
    ELSE 'C'
  END AS abc_curve
FROM accumulated
ORDER BY revenue DESC, product_id;
