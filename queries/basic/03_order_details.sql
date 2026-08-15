-- Detalhes financeiros e itens de um pedido.
SET @order_id = 1;

SELECT
  o.order_number,
  c.full_name AS customer,
  o.status,
  oi.product_sku,
  oi.product_name,
  oi.quantity,
  oi.unit_price,
  oi.line_total
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_id = @order_id
ORDER BY oi.order_item_id;
