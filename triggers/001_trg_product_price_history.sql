DROP TRIGGER IF EXISTS trg_product_price_history;
DELIMITER $$
CREATE TRIGGER trg_product_price_history
AFTER UPDATE ON products
FOR EACH ROW
BEGIN
  IF NOT (OLD.sale_price <=> NEW.sale_price) THEN
    INSERT INTO product_price_history (product_id, old_price, new_price, changed_by)
    VALUES (NEW.product_id, OLD.sale_price, NEW.sale_price, CURRENT_USER());
  END IF;
END$$
DELIMITER ;
