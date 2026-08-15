SELECT shipment_id, order_id, carrier, estimated_delivery_date, delivered_at
FROM shipments
WHERE status = 'DELIVERED' AND estimated_delivery_date BETWEEN '2025-01-01' AND '2026-08-01'
  AND DATE(delivered_at) > estimated_delivery_date
