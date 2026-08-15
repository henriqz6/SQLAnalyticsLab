DROP FUNCTION IF EXISTS fn_coupon_discount;
DELIMITER $$
CREATE FUNCTION fn_coupon_discount(
  p_subtotal DECIMAL(13,2),
  p_discount_type VARCHAR(20),
  p_discount_value DECIMAL(13,2),
  p_max_discount DECIMAL(13,2)
) RETURNS DECIMAL(13,2)
DETERMINISTIC
NO SQL
BEGIN
  DECLARE v_discount DECIMAL(13,2) DEFAULT 0;

  IF p_subtotal <= 0 OR p_discount_value <= 0 THEN
    RETURN 0;
  END IF;

  IF p_discount_type = 'PERCENTAGE' THEN
    SET v_discount = ROUND(p_subtotal * p_discount_value / 100, 2);
  ELSEIF p_discount_type = 'FIXED' THEN
    SET v_discount = p_discount_value;
  END IF;

  IF p_max_discount IS NOT NULL THEN
    SET v_discount = LEAST(v_discount, p_max_discount);
  END IF;

  RETURN LEAST(v_discount, p_subtotal);
END$$
DELIMITER ;
