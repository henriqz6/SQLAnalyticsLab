DROP TRIGGER IF EXISTS trg_inventory_movement_audit;
DELIMITER $$
CREATE TRIGGER trg_inventory_movement_audit
AFTER INSERT ON inventory_movements
FOR EACH ROW
BEGIN
  INSERT INTO audit_log (entity_type, entity_id, action, new_values, actor)
  VALUES (
    'INVENTORY_MOVEMENT',
    NEW.movement_id,
    NEW.movement_type,
    JSON_OBJECT(
      'productId', NEW.product_id,
      'quantityChange', NEW.quantity_change,
      'balanceAfter', NEW.balance_after,
      'referenceType', NEW.reference_type,
      'referenceId', NEW.reference_id
    ),
    NEW.created_by
  );
END$$
DELIMITER ;
