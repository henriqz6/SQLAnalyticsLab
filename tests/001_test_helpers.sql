DROP TABLE IF EXISTS test_results;
CREATE TABLE test_results (
  test_name VARCHAR(180) NOT NULL PRIMARY KEY,
  status ENUM('PASS','FAIL') NOT NULL,
  executed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
) ENGINE=InnoDB;

DROP PROCEDURE IF EXISTS assert_true;
DELIMITER $$
CREATE PROCEDURE assert_true(IN p_condition BOOLEAN, IN p_test_name VARCHAR(180))
BEGIN
  IF p_condition IS NULL OR p_condition = FALSE THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = p_test_name;
  END IF;
  INSERT INTO test_results (test_name, status) VALUES (p_test_name, 'PASS');
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS assert_equals_bigint;
DELIMITER $$
CREATE PROCEDURE assert_equals_bigint(IN p_expected BIGINT, IN p_actual BIGINT, IN p_test_name VARCHAR(180))
BEGIN
  IF NOT (p_expected <=> p_actual) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = p_test_name;
  END IF;
  INSERT INTO test_results (test_name, status) VALUES (p_test_name, 'PASS');
END$$
DELIMITER ;

CALL assert_equals_bigint(150, (SELECT COUNT(*) FROM customers), 'seed_has_150_customers');
CALL assert_equals_bigint(120, (SELECT COUNT(*) FROM products), 'seed_has_120_products');
CALL assert_equals_bigint(720, (SELECT COUNT(*) FROM orders), 'seed_has_720_orders');
CALL assert_equals_bigint(1440, (SELECT COUNT(*) FROM order_items), 'seed_has_1440_order_items');
