DROP PROCEDURE IF EXISTS sp_cancel_order;
DELIMITER $$
CREATE PROCEDURE sp_cancel_order(
  IN p_order_id BIGINT UNSIGNED,
  IN p_reason VARCHAR(240),
  IN p_actor VARCHAR(100)
)
BEGIN
  DECLARE v_status VARCHAR(20);
  DECLARE v_coupon_id BIGINT UNSIGNED;

  DECLARE EXIT HANDLER FOR NOT FOUND
  BEGIN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ORDER_NOT_FOUND';
  END;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_reason IS NULL OR TRIM(p_reason) = '' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'CANCELLATION_REASON_REQUIRED';
  END IF;

  START TRANSACTION;

  SELECT status, coupon_id INTO v_status, v_coupon_id
  FROM orders
  WHERE order_id = p_order_id
  FOR UPDATE;

  IF v_status IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ORDER_NOT_FOUND';
  END IF;

  IF v_status IN ('SHIPPED','DELIVERED','CANCELLED') THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ORDER_CANNOT_BE_CANCELLED';
  END IF;

  UPDATE inventory i
  JOIN order_items oi ON oi.product_id = i.product_id AND oi.order_id = p_order_id
  SET i.quantity_on_hand = i.quantity_on_hand + oi.quantity;

  INSERT INTO inventory_movements (
    product_id, movement_type, quantity_change, balance_after,
    reference_type, reference_id, reason, created_by
  )
  SELECT
    oi.product_id, 'CANCELLATION', oi.quantity, i.quantity_on_hand,
    'ORDER', p_order_id, CONCAT('Reposição por cancelamento: ', TRIM(p_reason)), COALESCE(NULLIF(TRIM(p_actor), ''), 'sp_cancel_order')
  FROM order_items oi
  JOIN inventory i ON i.product_id = oi.product_id
  WHERE oi.order_id = p_order_id;

  UPDATE orders
  SET status = 'CANCELLED', cancelled_at = UTC_TIMESTAMP(6), cancellation_reason = TRIM(p_reason)
  WHERE order_id = p_order_id;

  UPDATE payments
  SET status = CASE WHEN status = 'APPROVED' THEN 'REFUNDED' ELSE status END
  WHERE order_id = p_order_id;

  IF v_coupon_id IS NOT NULL THEN
    UPDATE coupons SET usage_count = GREATEST(usage_count - 1, 0) WHERE coupon_id = v_coupon_id;
  END IF;

  COMMIT;

  SELECT * FROM orders WHERE order_id = p_order_id;
END$$
DELIMITER ;
