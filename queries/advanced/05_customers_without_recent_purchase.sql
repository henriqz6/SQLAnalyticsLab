-- Problema: encontrar clientes ativos sem compra nos últimos 180 dias, incluindo quem nunca comprou.
-- Solução: LEFT JOIN com agregação mantém clientes sem pedidos.
SET @analysis_date = '2026-08-01';

SELECT
  c.customer_id,
  c.full_name,
  c.email,
  MAX(CASE WHEN o.status <> 'CANCELLED' THEN o.placed_at END) AS last_order_at,
  DATEDIFF(@analysis_date, DATE(MAX(CASE WHEN o.status <> 'CANCELLED' THEN o.placed_at END))) AS days_without_purchase
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
WHERE c.status = 'ACTIVE'
GROUP BY c.customer_id, c.full_name, c.email
HAVING last_order_at IS NULL OR last_order_at < @analysis_date - INTERVAL 180 DAY
ORDER BY last_order_at IS NULL DESC, last_order_at;
