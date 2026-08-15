CREATE OR REPLACE VIEW v_order_financials AS
SELECT
  o.order_id,
  o.order_number,
  o.customer_id,
  c.full_name AS customer_name,
  o.status,
  o.placed_at,
  o.subtotal_amount,
  o.discount_amount,
  o.shipping_amount,
  o.total_amount,
  COALESCE(SUM(oi.quantity * oi.unit_cost), 0) AS cost_amount,
  o.total_amount - o.shipping_amount - COALESCE(SUM(oi.quantity * oi.unit_cost), 0) AS gross_margin_amount
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY
  o.order_id, o.order_number, o.customer_id, c.full_name, o.status, o.placed_at,
  o.subtotal_amount, o.discount_amount, o.shipping_amount, o.total_amount;

CREATE OR REPLACE VIEW v_monthly_revenue AS
SELECT
  DATE_FORMAT(placed_at, '%Y-%m-01') AS month_start,
  COUNT(*) AS order_count,
  COUNT(DISTINCT customer_id) AS unique_customers,
  ROUND(SUM(total_amount), 2) AS revenue,
  ROUND(AVG(total_amount), 2) AS average_ticket
FROM orders
WHERE status IN ('PAID','PROCESSING','SHIPPED','DELIVERED')
GROUP BY DATE_FORMAT(placed_at, '%Y-%m-01');

CREATE OR REPLACE VIEW v_customer_360 AS
SELECT
  c.customer_id,
  c.full_name,
  c.email,
  c.created_at,
  COUNT(o.order_id) AS valid_order_count,
  COALESCE(SUM(o.total_amount), 0) AS lifetime_value,
  AVG(o.total_amount) AS average_ticket,
  MIN(o.placed_at) AS first_order_at,
  MAX(o.placed_at) AS last_order_at
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id AND o.status <> 'CANCELLED'
GROUP BY c.customer_id, c.full_name, c.email, c.created_at;

CREATE OR REPLACE VIEW v_product_performance AS
SELECT
  p.product_id,
  p.sku,
  p.name,
  p.active,
  COALESCE(SUM(CASE WHEN o.status <> 'CANCELLED' THEN oi.quantity ELSE 0 END), 0) AS units_sold,
  COALESCE(SUM(CASE WHEN o.status <> 'CANCELLED' THEN oi.line_total ELSE 0 END), 0) AS gross_item_revenue,
  COALESCE(SUM(ri.quantity), 0) AS units_returned,
  ROUND(AVG(CASE WHEN r.status = 'PUBLISHED' THEN r.rating END), 2) AS average_rating,
  MAX(CASE WHEN o.status <> 'CANCELLED' THEN o.placed_at END) AS last_sale_at
FROM products p
LEFT JOIN order_items oi ON oi.product_id = p.product_id
LEFT JOIN orders o ON o.order_id = oi.order_id
LEFT JOIN return_items ri ON ri.order_item_id = oi.order_item_id
LEFT JOIN reviews r ON r.order_item_id = oi.order_item_id
GROUP BY p.product_id, p.sku, p.name, p.active;

CREATE OR REPLACE VIEW v_inventory_health AS
SELECT
  p.product_id,
  p.sku,
  p.name,
  i.quantity_on_hand,
  i.reserved_quantity,
  i.reorder_point,
  i.quantity_on_hand - i.reserved_quantity AS available_quantity,
  CASE
    WHEN i.quantity_on_hand - i.reserved_quantity = 0 THEN 'OUT_OF_STOCK'
    WHEN i.quantity_on_hand - i.reserved_quantity <= i.reorder_point THEN 'LOW_STOCK'
    ELSE 'HEALTHY'
  END AS stock_status,
  pp.last_sale_at
FROM products p
JOIN inventory i ON i.product_id = p.product_id
LEFT JOIN v_product_performance pp ON pp.product_id = p.product_id;

CREATE OR REPLACE VIEW v_delivery_performance AS
SELECT
  s.carrier,
  COUNT(*) AS shipment_count,
  SUM(s.status = 'DELIVERED') AS delivered_count,
  SUM(s.status = 'DELIVERED' AND DATE(s.delivered_at) > s.estimated_delivery_date) AS late_count,
  ROUND(AVG(CASE WHEN s.status = 'DELIVERED' THEN TIMESTAMPDIFF(HOUR, s.shipped_at, s.delivered_at) END), 2) AS average_delivery_hours,
  ROUND(100 * SUM(s.status = 'DELIVERED' AND DATE(s.delivered_at) <= s.estimated_delivery_date) / NULLIF(SUM(s.status = 'DELIVERED'), 0), 2) AS on_time_rate_percent
FROM shipments s
GROUP BY s.carrier;

CREATE OR REPLACE VIEW v_coupon_performance AS
SELECT
  c.coupon_id,
  c.code,
  c.discount_type,
  COUNT(o.order_id) AS order_count,
  COALESCE(SUM(CASE WHEN o.status <> 'CANCELLED' THEN o.discount_amount ELSE 0 END), 0) AS discount_granted,
  COALESCE(SUM(CASE WHEN o.status <> 'CANCELLED' THEN o.total_amount ELSE 0 END), 0) AS revenue_generated,
  ROUND(AVG(CASE WHEN o.status <> 'CANCELLED' THEN o.total_amount END), 2) AS average_ticket
FROM coupons c
LEFT JOIN orders o ON o.coupon_id = c.coupon_id
GROUP BY c.coupon_id, c.code, c.discount_type;
