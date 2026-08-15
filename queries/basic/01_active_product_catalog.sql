-- Catálogo simples de produtos ativos com fornecedor e estoque disponível.
SELECT
  p.product_id,
  p.sku,
  p.name,
  s.trade_name AS supplier,
  p.sale_price,
  i.quantity_on_hand - i.reserved_quantity AS available_quantity
FROM products p
JOIN suppliers s ON s.supplier_id = p.supplier_id
JOIN inventory i ON i.product_id = p.product_id
WHERE p.active = TRUE
ORDER BY p.name;
