DROP PROCEDURE IF EXISTS test_safe_rollback;
DELIMITER $$
CREATE PROCEDURE test_safe_rollback()
BEGIN
  DECLARE v_stock_before INT UNSIGNED;

  SELECT quantity_on_hand INTO v_stock_before FROM inventory WHERE product_id = 3;

  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
      ROLLBACK;
    END;

    START TRANSACTION;
    UPDATE inventory SET quantity_on_hand = quantity_on_hand - 1 WHERE product_id = 3;
    INSERT INTO suppliers (legal_name, trade_name, tax_id, email)
    VALUES ('Fornecedor duplicado', 'Duplicado', '10000000000001', 'duplicado@example.test');
    COMMIT;
  END;

  CALL assert_true(
    (SELECT quantity_on_hand FROM inventory WHERE product_id = 3) = v_stock_before,
    'failed_transaction_rolls_back_stock_change'
  );
END$$
DELIMITER ;

CALL test_safe_rollback();
DROP PROCEDURE test_safe_rollback;

SELECT COUNT(*) AS total_passing_tests FROM test_results WHERE status = 'PASS';
