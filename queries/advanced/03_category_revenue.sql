-- Problema: atribuir receita por categoria sem dupla contagem de produtos multcategoria.
-- Solução: somente a categoria marcada como principal recebe a venda do produto.
SELECT
  c.category_id,
  c.name AS category,
  COUNT(DISTINCT o.order_id) AS order_count,
  SUM(oi.quantity) AS units_sold,
  ROUND(SUM(oi.line_total), 2) AS gross_item_revenue,
  DENSE_RANK() OVER (ORDER BY SUM(oi.line_total) DESC) AS revenue_rank
FROM categories c
JOIN product_categories pc ON pc.category_id = c.category_id AND pc.is_primary = TRUE
JOIN order_items oi ON oi.product_id = pc.product_id
JOIN orders o ON o.order_id = oi.order_id AND o.status <> 'CANCELLED'
GROUP BY c.category_id, c.name
ORDER BY revenue_rank, c.name;
