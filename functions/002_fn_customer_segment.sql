DROP FUNCTION IF EXISTS fn_customer_segment;
DELIMITER $$
CREATE FUNCTION fn_customer_segment(p_customer_id BIGINT UNSIGNED)
RETURNS VARCHAR(20)
READS SQL DATA
BEGIN
  DECLARE v_orders BIGINT DEFAULT 0;
  DECLARE v_spent DECIMAL(15,2) DEFAULT 0;
  DECLARE v_last_order DATETIME DEFAULT NULL;

  SELECT
    COUNT(*),
    COALESCE(SUM(total_amount), 0),
    MAX(placed_at)
  INTO v_orders, v_spent, v_last_order
  FROM orders
  WHERE customer_id = p_customer_id
    AND status <> 'CANCELLED';

  IF v_orders = 0 THEN
    RETURN 'PROSPECT';
  ELSEIF v_last_order < UTC_TIMESTAMP() - INTERVAL 180 DAY THEN
    RETURN 'INACTIVE';
  ELSEIF v_orders >= 8 OR v_spent >= 3000 THEN
    RETURN 'VIP';
  ELSEIF v_orders >= 3 THEN
    RETURN 'RECURRENT';
  END IF;

  RETURN 'NEW';
END$$
DELIMITER ;
