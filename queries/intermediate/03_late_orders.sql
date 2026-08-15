-- Pedidos entregues após a estimativa ou ainda não entregues depois do prazo.
SET @analysis_date = '2026-08-01';

SELECT
  o.order_number,
  c.full_name AS customer,
  s.carrier,
  s.status AS shipment_status,
  s.estimated_delivery_date,
  s.delivered_at,
  CASE
    WHEN s.delivered_at IS NOT NULL THEN DATEDIFF(DATE(s.delivered_at), s.estimated_delivery_date)
    ELSE DATEDIFF(@analysis_date, s.estimated_delivery_date)
  END AS days_late
FROM shipments s
JOIN orders o ON o.order_id = s.order_id
JOIN customers c ON c.customer_id = o.customer_id
WHERE (s.delivered_at IS NOT NULL AND DATE(s.delivered_at) > s.estimated_delivery_date)
   OR (s.delivered_at IS NULL AND s.estimated_delivery_date < @analysis_date)
ORDER BY days_late DESC, o.order_number;
