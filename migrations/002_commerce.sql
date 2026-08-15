CREATE TABLE orders (
  order_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_number VARCHAR(30) NOT NULL,
  customer_id BIGINT UNSIGNED NOT NULL,
  shipping_address_id BIGINT UNSIGNED NOT NULL,
  coupon_id BIGINT UNSIGNED NULL,
  status ENUM('PENDING','PAID','PROCESSING','SHIPPED','DELIVERED','CANCELLED') NOT NULL DEFAULT 'PENDING',
  subtotal_amount DECIMAL(13,2) NOT NULL DEFAULT 0,
  discount_amount DECIMAL(13,2) NOT NULL DEFAULT 0,
  shipping_amount DECIMAL(13,2) NOT NULL DEFAULT 0,
  total_amount DECIMAL(13,2) NOT NULL DEFAULT 0,
  placed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  cancelled_at DATETIME(6) NULL,
  cancellation_reason VARCHAR(240) NULL,
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  CONSTRAINT pk_orders PRIMARY KEY (order_id),
  CONSTRAINT uk_orders_number UNIQUE (order_number),
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT fk_orders_address FOREIGN KEY (shipping_address_id) REFERENCES addresses(address_id),
  CONSTRAINT fk_orders_coupon FOREIGN KEY (coupon_id) REFERENCES coupons(coupon_id) ON DELETE SET NULL,
  CONSTRAINT ck_orders_amounts CHECK (subtotal_amount >= 0 AND discount_amount >= 0 AND shipping_amount >= 0 AND total_amount >= 0),
  CONSTRAINT ck_orders_total CHECK (total_amount = subtotal_amount - discount_amount + shipping_amount),
  CONSTRAINT ck_orders_discount CHECK (discount_amount <= subtotal_amount),
  CONSTRAINT ck_orders_cancellation CHECK ((status = 'CANCELLED' AND cancelled_at IS NOT NULL AND cancellation_reason IS NOT NULL) OR status <> 'CANCELLED')
) ENGINE=InnoDB;

CREATE TABLE order_items (
  order_item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  product_sku VARCHAR(40) NOT NULL,
  product_name VARCHAR(180) NOT NULL,
  quantity SMALLINT UNSIGNED NOT NULL,
  unit_price DECIMAL(13,2) NOT NULL,
  unit_cost DECIMAL(13,2) NOT NULL,
  line_total DECIMAL(13,2) GENERATED ALWAYS AS (ROUND(quantity * unit_price, 2)) STORED,
  CONSTRAINT pk_order_items PRIMARY KEY (order_item_id),
  CONSTRAINT uk_order_items_product UNIQUE (order_id, product_id),
  CONSTRAINT fk_order_items_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
  CONSTRAINT fk_order_items_product FOREIGN KEY (product_id) REFERENCES products(product_id),
  CONSTRAINT ck_order_items_quantity CHECK (quantity > 0),
  CONSTRAINT ck_order_items_prices CHECK (unit_price >= 0 AND unit_cost >= 0)
) ENGINE=InnoDB;

CREATE TABLE payments (
  payment_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_id BIGINT UNSIGNED NOT NULL,
  method ENUM('PIX','CREDIT_CARD','DEBIT_CARD','BANK_SLIP') NOT NULL,
  status ENUM('PENDING','APPROVED','FAILED','PARTIALLY_REFUNDED','REFUNDED') NOT NULL DEFAULT 'PENDING',
  amount DECIMAL(13,2) NOT NULL,
  transaction_reference VARCHAR(80) NOT NULL,
  paid_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT pk_payments PRIMARY KEY (payment_id),
  CONSTRAINT uk_payments_transaction UNIQUE (transaction_reference),
  CONSTRAINT fk_payments_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
  CONSTRAINT ck_payments_amount CHECK (amount > 0),
  CONSTRAINT ck_payments_paid_at CHECK ((status IN ('APPROVED','PARTIALLY_REFUNDED','REFUNDED') AND paid_at IS NOT NULL) OR status IN ('PENDING','FAILED'))
) ENGINE=InnoDB;

CREATE TABLE shipments (
  shipment_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_id BIGINT UNSIGNED NOT NULL,
  carrier VARCHAR(100) NOT NULL,
  tracking_code VARCHAR(80) NOT NULL,
  status ENUM('PREPARING','IN_TRANSIT','DELIVERED','LOST') NOT NULL DEFAULT 'PREPARING',
  estimated_delivery_date DATE NOT NULL,
  shipped_at DATETIME(6) NULL,
  delivered_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT pk_shipments PRIMARY KEY (shipment_id),
  CONSTRAINT uk_shipments_order UNIQUE (order_id),
  CONSTRAINT uk_shipments_tracking UNIQUE (tracking_code),
  CONSTRAINT fk_shipments_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
  CONSTRAINT ck_shipments_dates CHECK (delivered_at IS NULL OR (shipped_at IS NOT NULL AND delivered_at >= shipped_at)),
  CONSTRAINT ck_shipments_delivery CHECK (status <> 'DELIVERED' OR delivered_at IS NOT NULL)
) ENGINE=InnoDB;

CREATE TABLE returns (
  return_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_id BIGINT UNSIGNED NOT NULL,
  status ENUM('REQUESTED','APPROVED','REJECTED','RECEIVED','REFUNDED') NOT NULL DEFAULT 'REQUESTED',
  requested_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  processed_at DATETIME(6) NULL,
  total_refund_amount DECIMAL(13,2) NOT NULL DEFAULT 0,
  notes VARCHAR(500) NULL,
  CONSTRAINT pk_returns PRIMARY KEY (return_id),
  CONSTRAINT fk_returns_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
  CONSTRAINT ck_returns_refund CHECK (total_refund_amount >= 0)
) ENGINE=InnoDB;

CREATE TABLE return_items (
  return_item_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  return_id BIGINT UNSIGNED NOT NULL,
  order_item_id BIGINT UNSIGNED NOT NULL,
  quantity SMALLINT UNSIGNED NOT NULL,
  reason ENUM('DEFECTIVE','WRONG_ITEM','DAMAGED','REGRET','OTHER') NOT NULL,
  condition_on_arrival ENUM('SEALED','OPENED','DAMAGED') NOT NULL,
  refund_amount DECIMAL(13,2) NOT NULL,
  CONSTRAINT pk_return_items PRIMARY KEY (return_item_id),
  CONSTRAINT uk_return_items_order_item UNIQUE (return_id, order_item_id),
  CONSTRAINT fk_return_items_return FOREIGN KEY (return_id) REFERENCES returns(return_id) ON DELETE CASCADE,
  CONSTRAINT fk_return_items_order_item FOREIGN KEY (order_item_id) REFERENCES order_items(order_item_id),
  CONSTRAINT ck_return_items_quantity CHECK (quantity > 0),
  CONSTRAINT ck_return_items_refund CHECK (refund_amount >= 0)
) ENGINE=InnoDB;

CREATE TABLE reviews (
  review_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id BIGINT UNSIGNED NOT NULL,
  product_id BIGINT UNSIGNED NOT NULL,
  order_item_id BIGINT UNSIGNED NOT NULL,
  rating TINYINT UNSIGNED NOT NULL,
  title VARCHAR(120) NULL,
  comment VARCHAR(1000) NULL,
  status ENUM('PUBLISHED','HIDDEN') NOT NULL DEFAULT 'PUBLISHED',
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT pk_reviews PRIMARY KEY (review_id),
  CONSTRAINT uk_reviews_purchase UNIQUE (customer_id, product_id, order_item_id),
  CONSTRAINT fk_reviews_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
  CONSTRAINT fk_reviews_product FOREIGN KEY (product_id) REFERENCES products(product_id),
  CONSTRAINT fk_reviews_order_item FOREIGN KEY (order_item_id) REFERENCES order_items(order_item_id),
  CONSTRAINT ck_reviews_rating CHECK (rating BETWEEN 1 AND 5)
) ENGINE=InnoDB;

CREATE TABLE order_status_history (
  history_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  order_id BIGINT UNSIGNED NOT NULL,
  old_status VARCHAR(30) NULL,
  new_status VARCHAR(30) NOT NULL,
  reason VARCHAR(240) NOT NULL,
  changed_by VARCHAR(100) NOT NULL DEFAULT 'system',
  changed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT pk_order_status_history PRIMARY KEY (history_id),
  CONSTRAINT fk_order_status_history_order FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE audit_log (
  audit_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  entity_type VARCHAR(40) NOT NULL,
  entity_id BIGINT UNSIGNED NOT NULL,
  action VARCHAR(40) NOT NULL,
  old_values JSON NULL,
  new_values JSON NULL,
  actor VARCHAR(100) NOT NULL DEFAULT 'system',
  occurred_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT pk_audit_log PRIMARY KEY (audit_id)
) ENGINE=InnoDB;
