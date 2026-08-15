-- Problema: comparar fornecedores por receita e margem bruta dos itens vendidos.
-- Solução: preços e custos congelados no item preservam a verdade histórica.
SELECT
  s.supplier_id,
  s.trade_name AS supplier,
  COUNT(DISTINCT o.order_id) AS order_count,
  SUM(oi.quantity) AS units_sold,
  ROUND(SUM(oi.line_total), 2) AS item_revenue,
  ROUND(SUM(oi.quantity * oi.unit_cost), 2) AS item_cost,
  ROUND(SUM(oi.line_total - oi.quantity * oi.unit_cost), 2) AS gross_margin,
  ROUND(100 * SUM(oi.line_total - oi.quantity * oi.unit_cost) / NULLIF(SUM(oi.line_total), 0), 2) AS margin_percent
FROM suppliers s
JOIN products p ON p.supplier_id = s.supplier_id
JOIN order_items oi ON oi.product_id = p.product_id
JOIN orders o ON o.order_id = oi.order_id AND o.status <> 'CANCELLED'
GROUP BY s.supplier_id, s.trade_name
ORDER BY gross_margin DESC;
