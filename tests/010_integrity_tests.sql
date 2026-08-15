DROP PROCEDURE IF EXISTS test_integrity_constraints;
DELIMITER $$
CREATE PROCEDURE test_integrity_constraints()
BEGIN
  DECLARE v_rejected BOOLEAN DEFAULT FALSE;

  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET v_rejected = TRUE;
    INSERT INTO order_items (order_id, product_id, product_sku, product_name, quantity, unit_price, unit_cost)
    VALUES (1, 119, 'INVALID', 'Quantidade inválida', 0, 10, 5);
  END;
  CALL assert_true(v_rejected, 'rejects_zero_item_quantity');

  SET v_rejected = FALSE;
  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET v_rejected = TRUE;
    UPDATE products SET sale_price = cost_price - 1 WHERE product_id = 1;
  END;
  CALL assert_true(v_rejected, 'rejects_price_below_cost');

  SET v_rejected = FALSE;
  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET v_rejected = TRUE;
    INSERT INTO addresses (customer_id, street, number, district, city, state, postal_code)
    VALUES (999999, 'Rua inválida', '0', 'Centro', 'São Paulo', 'SP', '01001000');
  END;
  CALL assert_true(v_rejected, 'rejects_orphan_address');

  SET v_rejected = FALSE;
  BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET v_rejected = TRUE;
    UPDATE inventory SET reserved_quantity = quantity_on_hand + 1 WHERE product_id = 2;
  END;
  CALL assert_true(v_rejected, 'rejects_reserved_stock_above_on_hand');
END$$
DELIMITER ;

CALL test_integrity_constraints();
DROP PROCEDURE test_integrity_constraints;
