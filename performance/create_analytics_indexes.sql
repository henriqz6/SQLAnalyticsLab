CREATE INDEX idx_orders_placed_status ON orders (placed_at, status);
CREATE INDEX idx_orders_customer_placed ON orders (customer_id, placed_at DESC);
CREATE INDEX idx_orders_coupon_status ON orders (coupon_id, status, placed_at);
CREATE INDEX idx_order_items_product_order ON order_items (product_id, order_id);
CREATE INDEX idx_shipments_status_estimated ON shipments (status, estimated_delivery_date);
