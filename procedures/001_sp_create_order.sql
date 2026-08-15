DROP PROCEDURE IF EXISTS sp_create_order;
DELIMITER $$
CREATE PROCEDURE sp_create_order(
  IN p_customer_id BIGINT UNSIGNED,
  IN p_shipping_address_id BIGINT UNSIGNED,
  IN p_coupon_code VARCHAR(40),
  IN p_shipping_amount DECIMAL(13,2),
  IN p_items JSON,
  OUT p_order_id BIGINT UNSIGNED
)
BEGIN
  DECLARE v_item_count INT DEFAULT 0;
  DECLARE v_index INT DEFAULT 0;
  DECLARE v_product_id BIGINT UNSIGNED;
  DECLARE v_quantity INT;
  DECLARE v_stock INT UNSIGNED;
  DECLARE v_price DECIMAL(13,2);
  DECLARE v_cost DECIMAL(13,2);
  DECLARE v_sku VARCHAR(40);
  DECLARE v_name VARCHAR(180);
  DECLARE v_subtotal DECIMAL(13,2) DEFAULT 0;
  DECLARE v_discount DECIMAL(13,2) DEFAULT 0;
  DECLARE v_coupon_id BIGINT UNSIGNED DEFAULT NULL;
  DECLARE v_discount_type VARCHAR(20);
  DECLARE v_discount_value DECIMAL(13,2);
  DECLARE v_max_discount DECIMAL(13,2);
  DECLARE v_minimum_order DECIMAL(13,2);
  DECLARE v_usage_limit INT UNSIGNED;
  DECLARE v_usage_count INT UNSIGNED;
  DECLARE v_coupon_starts DATETIME;
  DECLARE v_coupon_ends DATETIME;

  DECLARE EXIT HANDLER FOR NOT FOUND
  BEGIN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PRODUCT_OR_COUPON_NOT_FOUND';
  END;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_customer_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM customers WHERE customer_id = p_customer_id AND status = 'ACTIVE'
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CUSTOMER_NOT_ACTIVE';
  END IF;

  IF p_shipping_address_id IS NULL OR NOT EXISTS (
    SELECT 1 FROM addresses WHERE address_id = p_shipping_address_id AND customer_id = p_customer_id
  ) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ADDRESS_NOT_OWNED_BY_CUSTOMER';
  END IF;

  IF p_shipping_amount IS NULL OR p_shipping_amount < 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_SHIPPING_AMOUNT';
  END IF;

  IF p_items IS NULL OR JSON_TYPE(p_items) <> 'ARRAY' OR JSON_LENGTH(p_items) = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ORDER_ITEMS_REQUIRED';
  END IF;

  SET v_item_count = JSON_LENGTH(p_items);
  START TRANSACTION;

  INSERT INTO orders (
    order_number, customer_id, shipping_address_id, status,
    subtotal_amount, discount_amount, shipping_amount, total_amount, placed_at
  ) VALUES (
    CONCAT('TMP-', UUID()), p_customer_id, p_shipping_address_id, 'PENDING',
    0, 0, p_shipping_amount, p_shipping_amount, UTC_TIMESTAMP(6)
  );

  SET p_order_id = LAST_INSERT_ID();
  UPDATE orders SET order_number = CONCAT('PED-', DATE_FORMAT(UTC_DATE(), '%Y%m'), '-', LPAD(p_order_id, 8, '0')) WHERE order_id = p_order_id;

  WHILE v_index < v_item_count DO
    SET v_product_id = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_index, '].productId'))) AS UNSIGNED);
    SET v_quantity = CAST(JSON_UNQUOTE(JSON_EXTRACT(p_items, CONCAT('$[', v_index, '].quantity'))) AS UNSIGNED);

    IF v_product_id IS NULL OR v_quantity IS NULL OR v_quantity <= 0 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INVALID_ORDER_ITEM';
    END IF;

    IF EXISTS (SELECT 1 FROM order_items WHERE order_id = p_order_id AND product_id = v_product_id) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'DUPLICATE_PRODUCT_IN_ORDER';
    END IF;

    SELECT p.sku, p.name, p.sale_price, p.cost_price, i.quantity_on_hand - i.reserved_quantity
    INTO v_sku, v_name, v_price, v_cost, v_stock
    FROM products p
    JOIN inventory i ON i.product_id = p.product_id
    WHERE p.product_id = v_product_id AND p.active = TRUE
    FOR UPDATE;

    IF v_stock IS NULL OR v_stock < v_quantity THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INSUFFICIENT_STOCK';
    END IF;

    INSERT INTO order_items (order_id, product_id, product_sku, product_name, quantity, unit_price, unit_cost)
    VALUES (p_order_id, v_product_id, v_sku, v_name, v_quantity, v_price, v_cost);

    UPDATE inventory
    SET quantity_on_hand = quantity_on_hand - v_quantity
    WHERE product_id = v_product_id;

    SET v_stock = v_stock - v_quantity;
    INSERT INTO inventory_movements (
      product_id, movement_type, quantity_change, balance_after,
      reference_type, reference_id, reason, created_by
    ) VALUES (
      v_product_id, 'SALE', -v_quantity, v_stock,
      'ORDER', p_order_id, 'Saída controlada pela sp_create_order', 'sp_create_order'
    );

    SET v_subtotal = v_subtotal + (v_quantity * v_price);
    SET v_index = v_index + 1;
  END WHILE;

  IF p_coupon_code IS NOT NULL AND TRIM(p_coupon_code) <> '' THEN
    IF NOT EXISTS (
      SELECT 1 FROM coupons
      WHERE code = UPPER(TRIM(p_coupon_code)) AND active = TRUE
    ) THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'COUPON_NOT_FOUND_OR_INACTIVE';
    END IF;

    SELECT coupon_id, discount_type, discount_value, max_discount_amount,
           minimum_order_amount, usage_limit, usage_count, starts_at, ends_at
    INTO v_coupon_id, v_discount_type, v_discount_value, v_max_discount,
         v_minimum_order, v_usage_limit, v_usage_count, v_coupon_starts, v_coupon_ends
    FROM coupons
    WHERE code = UPPER(TRIM(p_coupon_code))
    FOR UPDATE;

    IF UTC_TIMESTAMP() NOT BETWEEN v_coupon_starts AND v_coupon_ends THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'COUPON_OUTSIDE_VALIDITY';
    END IF;
    IF v_usage_limit IS NOT NULL AND v_usage_count >= v_usage_limit THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'COUPON_USAGE_LIMIT_REACHED';
    END IF;
    IF v_subtotal < v_minimum_order THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'COUPON_MINIMUM_NOT_REACHED';
    END IF;

    SET v_discount = fn_coupon_discount(v_subtotal, v_discount_type, v_discount_value, v_max_discount);
    UPDATE coupons SET usage_count = usage_count + 1 WHERE coupon_id = v_coupon_id;
  END IF;

  UPDATE orders
  SET coupon_id = v_coupon_id,
      subtotal_amount = ROUND(v_subtotal, 2),
      discount_amount = ROUND(v_discount, 2),
      total_amount = ROUND(v_subtotal - v_discount + p_shipping_amount, 2)
  WHERE order_id = p_order_id;

  INSERT INTO order_status_history (order_id, old_status, new_status, reason, changed_by)
  VALUES (p_order_id, NULL, 'PENDING', 'Pedido criado pela procedure', 'sp_create_order');

  COMMIT;

  SELECT * FROM orders WHERE order_id = p_order_id;
END$$
DELIMITER ;
