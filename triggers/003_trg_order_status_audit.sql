DROP TRIGGER IF EXISTS trg_order_status_audit;
DELIMITER $$
CREATE TRIGGER trg_order_status_audit
AFTER UPDATE ON orders
FOR EACH ROW
BEGIN
  IF NOT (OLD.status <=> NEW.status) THEN
    INSERT INTO order_status_history (order_id, old_status, new_status, reason, changed_by)
    VALUES (
      NEW.order_id,
      OLD.status,
      NEW.status,
      COALESCE(NEW.cancellation_reason, 'Alteração de estado do pedido'),
      CURRENT_USER()
    );

    INSERT INTO audit_log (entity_type, entity_id, action, old_values, new_values, actor)
    VALUES (
      'ORDER',
      NEW.order_id,
      'STATUS_CHANGED',
      JSON_OBJECT('status', OLD.status),
      JSON_OBJECT('status', NEW.status),
      CURRENT_USER()
    );
  END IF;
END$$
DELIMITER ;
