DROP PROCEDURE IF EXISTS sp_restock_product;
DELIMITER $$
CREATE PROCEDURE sp_restock_product(
  IN p_product_id BIGINT UNSIGNED,
  IN p_quantity INT UNSIGNED,
  IN p_reason VARCHAR(240),
  IN p_actor VARCHAR(100)
)
BEGIN
  DECLARE v_balance INT UNSIGNED;

  DECLARE EXIT HANDLER FOR NOT FOUND
  BEGIN
    ROLLBACK;
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PRODUCT_INVENTORY_NOT_FOUND';
  END;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    ROLLBACK;
    RESIGNAL;
  END;

  IF p_quantity IS NULL OR p_quantity = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'RESTOCK_QUANTITY_MUST_BE_POSITIVE';
  END IF;

  START TRANSACTION;

  SELECT quantity_on_hand INTO v_balance
  FROM inventory
  WHERE product_id = p_product_id
  FOR UPDATE;

  IF v_balance IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'PRODUCT_INVENTORY_NOT_FOUND';
  END IF;

  SET v_balance = v_balance + p_quantity;
  UPDATE inventory SET quantity_on_hand = v_balance WHERE product_id = p_product_id;

  INSERT INTO inventory_movements (
    product_id, movement_type, quantity_change, balance_after,
    reference_type, reference_id, reason, created_by
  ) VALUES (
    p_product_id, 'PURCHASE', p_quantity, v_balance,
    'RESTOCK', NULL, COALESCE(NULLIF(TRIM(p_reason), ''), 'Reposição de estoque'), COALESCE(NULLIF(TRIM(p_actor), ''), 'sp_restock_product')
  );

  COMMIT;

  SELECT * FROM inventory WHERE product_id = p_product_id;
END$$
DELIMITER ;
