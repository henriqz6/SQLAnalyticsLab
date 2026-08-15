DROP PROCEDURE IF EXISTS test_business_procedures;
DELIMITER $$
CREATE PROCEDURE test_business_procedures()
BEGIN
  DECLARE v_before_stock INT UNSIGNED;
  DECLARE v_after_restock INT UNSIGNED;
  DECLARE v_after_order INT UNSIGNED;
  DECLARE v_new_order_id BIGINT UNSIGNED;
  DECLARE v_price_history_before BIGINT;

  SELECT quantity_on_hand INTO v_before_stock FROM inventory WHERE product_id = 1;
  CALL sp_restock_product(1, 10, 'Teste automatizado de reposição', 'sql-test');
  SELECT quantity_on_hand INTO v_after_restock FROM inventory WHERE product_id = 1;
  CALL assert_true(v_after_restock = v_before_stock + 10, 'restock_increases_inventory');

  CALL sp_create_order(
    1,
    1,
    NULL,
    18.90,
    JSON_ARRAY(JSON_OBJECT('productId', 1, 'quantity', 2)),
    v_new_order_id
  );

  SELECT quantity_on_hand INTO v_after_order FROM inventory WHERE product_id = 1;
  CALL assert_true(v_after_order = v_after_restock - 2, 'create_order_decreases_inventory');
  CALL assert_true(
    (SELECT total_amount = subtotal_amount - discount_amount + shipping_amount FROM orders WHERE order_id = v_new_order_id),
    'create_order_preserves_financial_equation'
  );

  CALL sp_cancel_order(v_new_order_id, 'Cancelamento pelo teste automatizado', 'sql-test');
  CALL assert_true(
    (SELECT status = 'CANCELLED' FROM orders WHERE order_id = v_new_order_id),
    'cancel_order_changes_status'
  );
  CALL assert_true(
    (SELECT quantity_on_hand FROM inventory WHERE product_id = 1) = v_after_restock,
    'cancel_order_restores_inventory'
  );

  SELECT COUNT(*) INTO v_price_history_before FROM product_price_history WHERE product_id = 1;
  UPDATE products SET sale_price = sale_price + 1 WHERE product_id = 1;
  CALL assert_true(
    (SELECT COUNT(*) FROM product_price_history WHERE product_id = 1) = v_price_history_before + 1,
    'price_update_creates_history'
  );
  UPDATE products SET sale_price = sale_price - 1 WHERE product_id = 1;

  CALL assert_true(
    (SELECT COUNT(*) FROM audit_log WHERE actor IN ('sql-test','sp_create_order')) >= 3,
    'business_operations_create_audit_events'
  );

  DELETE FROM orders WHERE order_id = v_new_order_id;
END$$
DELIMITER ;

CALL test_business_procedures();
DROP PROCEDURE test_business_procedures;

SELECT status, COUNT(*) AS test_count
FROM test_results
GROUP BY status;
