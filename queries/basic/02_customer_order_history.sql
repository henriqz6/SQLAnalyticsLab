-- Histórico de um cliente. Troque o valor da variável para explorar outro cliente.
SET @customer_id = 1;

SELECT
  o.order_number,
  o.status,
  o.placed_at,
  o.subtotal_amount,
  o.discount_amount,
  o.shipping_amount,
  o.total_amount
FROM orders o
WHERE o.customer_id = @customer_id
ORDER BY o.placed_at DESC;
