-- Ticket médio e dispersão por estado do pedido.
SELECT
  status,
  COUNT(*) AS order_count,
  ROUND(AVG(total_amount), 2) AS average_ticket,
  MIN(total_amount) AS minimum_ticket,
  MAX(total_amount) AS maximum_ticket
FROM orders
GROUP BY status
ORDER BY order_count DESC;
