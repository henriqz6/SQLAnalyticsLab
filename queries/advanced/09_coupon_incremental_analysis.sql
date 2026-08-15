-- Problema: comparar pedidos com e sem cupom sem afirmar causalidade.
-- Solução: grupos observacionais mostram volume, ticket e desconto; o comentário evita interpretação causal.
SELECT
  CASE WHEN coupon_id IS NULL THEN 'WITHOUT_COUPON' ELSE 'WITH_COUPON' END AS coupon_group,
  COUNT(*) AS order_count,
  ROUND(AVG(subtotal_amount), 2) AS average_subtotal,
  ROUND(AVG(total_amount), 2) AS average_ticket,
  ROUND(SUM(discount_amount), 2) AS discount_granted,
  ROUND(SUM(total_amount), 2) AS revenue
FROM orders
WHERE status <> 'CANCELLED'
GROUP BY CASE WHEN coupon_id IS NULL THEN 'WITHOUT_COUPON' ELSE 'WITH_COUPON' END
ORDER BY coupon_group;
