SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE audit_log;
TRUNCATE TABLE order_status_history;
TRUNCATE TABLE reviews;
TRUNCATE TABLE return_items;
TRUNCATE TABLE returns;
TRUNCATE TABLE shipments;
TRUNCATE TABLE payments;
TRUNCATE TABLE order_items;
TRUNCATE TABLE orders;
TRUNCATE TABLE inventory_movements;
TRUNCATE TABLE inventory;
TRUNCATE TABLE product_price_history;
TRUNCATE TABLE product_categories;
TRUNCATE TABLE products;
TRUNCATE TABLE categories;
TRUNCATE TABLE suppliers;
TRUNCATE TABLE addresses;
TRUNCATE TABLE customers;
TRUNCATE TABLE coupons;

SET FOREIGN_KEY_CHECKS = 1;

CREATE TEMPORARY TABLE seed_numbers (n INT UNSIGNED NOT NULL PRIMARY KEY);
INSERT INTO seed_numbers
WITH RECURSIVE seq AS (
  SELECT 1 AS n
  UNION ALL
  SELECT n + 1 FROM seq WHERE n < 1000
)
SELECT n FROM seq;

INSERT INTO suppliers (supplier_id, legal_name, trade_name, tax_id, email, lead_time_days, active) VALUES
  (1,'Aurora Tecnologia Ltda.','Aurora Tech','10000000000001','contato@auroratech.example',4,TRUE),
  (2,'Casa Nativa Comércio Ltda.','Casa Nativa','10000000000002','contato@casanativa.example',7,TRUE),
  (3,'Movimento Esportes S.A.','Movimento','10000000000003','contato@movimento.example',6,TRUE),
  (4,'Papelaria Horizonte Ltda.','Horizonte','10000000000004','contato@horizonte.example',3,TRUE),
  (5,'Som & Cena Distribuidora Ltda.','Som & Cena','10000000000005','contato@somecena.example',8,TRUE),
  (6,'Bem Estar Brasil Ltda.','Bem Estar','10000000000006','contato@bemestar.example',5,TRUE),
  (7,'Cozinha Viva Utilidades Ltda.','Cozinha Viva','10000000000007','contato@cozinhaviva.example',9,TRUE),
  (8,'Brinca Mundo Indústria Ltda.','Brinca Mundo','10000000000008','contato@brincamundo.example',10,TRUE),
  (9,'Estilo Urbano Confecções Ltda.','Estilo Urbano','10000000000009','contato@estilourbano.example',6,TRUE),
  (10,'Verde Lar Comércio Ltda.','Verde Lar','10000000000010','contato@verdelar.example',12,TRUE);

INSERT INTO categories (category_id, parent_category_id, name, slug, active) VALUES
  (1,NULL,'Tecnologia','tecnologia',TRUE),
  (2,1,'Acessórios de informática','acessorios-informatica',TRUE),
  (3,NULL,'Casa','casa',TRUE),
  (4,3,'Cozinha','cozinha',TRUE),
  (5,NULL,'Esportes','esportes',TRUE),
  (6,NULL,'Papelaria','papelaria',TRUE),
  (7,NULL,'Áudio e vídeo','audio-video',TRUE),
  (8,NULL,'Saúde e bem-estar','saude-bem-estar',TRUE),
  (9,NULL,'Brinquedos','brinquedos',TRUE),
  (10,NULL,'Moda','moda',TRUE),
  (11,3,'Decoração','decoracao',TRUE),
  (12,NULL,'Jardim','jardim',TRUE);

INSERT INTO customers (customer_id, full_name, email, phone, birth_date, status, created_at)
SELECT
  n,
  CONCAT('Cliente Demonstração ', LPAD(n, 3, '0')),
  CONCAT('cliente', LPAD(n, 3, '0'), '@example.test'),
  CONCAT('119', LPAD(10000000 + n, 8, '0')),
  DATE_ADD('1975-01-01', INTERVAL ((n * 137) MOD 9000) DAY),
  CASE WHEN n % 37 = 0 THEN 'INACTIVE' ELSE 'ACTIVE' END,
  DATE_ADD('2023-01-01 09:00:00', INTERVAL ((n * 11) MOD 900) DAY)
FROM seed_numbers WHERE n <= 150;

INSERT INTO addresses (address_id, customer_id, label, street, number, district, city, state, postal_code, is_default, created_at)
SELECT
  n,
  n,
  'Principal',
  CONCAT('Rua Demonstração ', ((n - 1) % 30) + 1),
  CAST(100 + n AS CHAR),
  CONCAT('Bairro ', ((n - 1) % 12) + 1),
  CASE n % 5 WHEN 0 THEN 'Campinas' WHEN 1 THEN 'São Paulo' WHEN 2 THEN 'Guarulhos' WHEN 3 THEN 'Osasco' ELSE 'Santo André' END,
  'SP',
  LPAD(1000000 + n, 8, '0'),
  TRUE,
  DATE_ADD('2023-01-01 09:00:00', INTERVAL ((n * 11) MOD 900) DAY)
FROM seed_numbers WHERE n <= 150;

INSERT INTO products (product_id, supplier_id, sku, name, description, cost_price, sale_price, weight_grams, active, created_at)
SELECT
  n,
  ((n - 1) % 10) + 1,
  CONCAT('SKU-', LPAD(n, 4, '0')),
  CONCAT('Produto Analítico ', LPAD(n, 3, '0')),
  CONCAT('Produto fictício ', n, ' para demonstração de consultas SQL.'),
  ROUND(8 + ((n * 17) % 180) + (n % 7) * 0.35, 2),
  ROUND((8 + ((n * 17) % 180) + (n % 7) * 0.35) * (1.35 + (n % 5) * 0.08), 2),
  100 + ((n * 83) % 4900),
  CASE WHEN n % 41 = 0 THEN FALSE ELSE TRUE END,
  DATE_ADD('2023-02-01 10:00:00', INTERVAL ((n * 7) MOD 700) DAY)
FROM seed_numbers WHERE n <= 120;

INSERT INTO product_categories (product_id, category_id, is_primary)
SELECT n, ((n - 1) % 12) + 1, TRUE FROM seed_numbers WHERE n <= 120;

INSERT INTO product_categories (product_id, category_id, is_primary)
SELECT n, ((n + 4) % 12) + 1, FALSE FROM seed_numbers WHERE n <= 120 AND n % 4 = 0;

INSERT INTO product_price_history (product_id, old_price, new_price, changed_at, changed_by)
SELECT product_id, NULL, sale_price, created_at, 'seed' FROM products;

INSERT INTO inventory (product_id, quantity_on_hand, reserved_quantity, reorder_point)
SELECT product_id, 150, 0, 20 + (product_id % 16) FROM products;

INSERT INTO inventory_movements (product_id, movement_type, quantity_change, balance_after, reference_type, reference_id, reason, created_at, created_by)
SELECT product_id, 'INITIAL', 150, 150, 'SEED', product_id, 'Carga inicial determinística', '2024-01-01 08:00:00', 'seed' FROM products;

INSERT INTO coupons (coupon_id, code, discount_type, discount_value, max_discount_amount, minimum_order_amount, starts_at, ends_at, usage_limit, usage_count, active) VALUES
  (1,'BEMVINDO10','PERCENTAGE',10.00,40.00,80.00,'2024-01-01','2030-12-31',10000,0,TRUE),
  (2,'MENOS20','FIXED',20.00,NULL,150.00,'2024-01-01','2030-12-31',10000,0,TRUE),
  (3,'CASA15','PERCENTAGE',15.00,60.00,220.00,'2024-01-01','2030-12-31',10000,0,TRUE),
  (4,'FRETE25','FIXED',25.00,NULL,250.00,'2024-01-01','2030-12-31',10000,0,TRUE),
  (5,'EXPIRADO','PERCENTAGE',30.00,100.00,100.00,'2023-01-01','2023-12-31',100,0,FALSE),
  (6,'LIMITADO','FIXED',35.00,NULL,200.00,'2024-01-01','2030-12-31',3,3,TRUE);

INSERT INTO orders (
  order_id, order_number, customer_id, shipping_address_id, coupon_id, status,
  subtotal_amount, discount_amount, shipping_amount, total_amount,
  placed_at, cancelled_at, cancellation_reason
)
SELECT
  n,
  CONCAT('PED-', DATE_FORMAT(DATE_ADD('2024-08-01', INTERVAL (n - 1) DAY), '%Y%m'), '-', LPAD(n, 6, '0')),
  ((n - 1) % 150) + 1,
  ((n - 1) % 150) + 1,
  CASE WHEN n % 30 = 0 THEN 2 WHEN n % 10 = 0 THEN 1 ELSE NULL END,
  CASE
    WHEN n % 20 = 0 THEN 'CANCELLED'
    WHEN n % 11 = 0 THEN 'PENDING'
    WHEN n % 7 = 0 THEN 'SHIPPED'
    WHEN n % 5 = 0 THEN 'PROCESSING'
    WHEN n % 3 = 0 THEN 'PAID'
    ELSE 'DELIVERED'
  END,
  0, 0, 0, 0,
  DATE_ADD('2024-08-01 10:00:00', INTERVAL (n - 1) DAY),
  CASE WHEN n % 20 = 0 THEN DATE_ADD('2024-08-01 10:00:00', INTERVAL n DAY) ELSE NULL END,
  CASE WHEN n % 20 = 0 THEN 'Cancelamento de demonstração' ELSE NULL END
FROM seed_numbers WHERE n <= 720;

INSERT INTO order_items (order_id, product_id, product_sku, product_name, quantity, unit_price, unit_cost)
SELECT
  o.order_id,
  p.product_id,
  p.sku,
  p.name,
  1 + ((o.order_id + offsets.item_offset) % 3),
  p.sale_price,
  p.cost_price
FROM orders o
CROSS JOIN (SELECT 0 AS item_offset UNION ALL SELECT 1) offsets
JOIN products p ON p.product_id = (((o.order_id * 7) + (offsets.item_offset * 31) - 1) % 120) + 1;

UPDATE orders o
JOIN (
  SELECT order_id, SUM(line_total) AS subtotal
  FROM order_items
  GROUP BY order_id
) totals ON totals.order_id = o.order_id
SET
  o.subtotal_amount = totals.subtotal,
  o.discount_amount = CASE
    WHEN o.coupon_id = 1 AND totals.subtotal >= 80 THEN LEAST(ROUND(totals.subtotal * 0.10, 2), 40.00)
    WHEN o.coupon_id = 2 AND totals.subtotal >= 150 THEN 20.00
    ELSE 0
  END,
  o.shipping_amount = CASE WHEN totals.subtotal >= 250 THEN 0 ELSE 18.90 END,
  o.total_amount = totals.subtotal
    - CASE
        WHEN o.coupon_id = 1 AND totals.subtotal >= 80 THEN LEAST(ROUND(totals.subtotal * 0.10, 2), 40.00)
        WHEN o.coupon_id = 2 AND totals.subtotal >= 150 THEN 20.00
        ELSE 0
      END
    + CASE WHEN totals.subtotal >= 250 THEN 0 ELSE 18.90 END;

UPDATE coupons c
LEFT JOIN (
  SELECT coupon_id, COUNT(*) AS uses_count
  FROM orders
  WHERE coupon_id IS NOT NULL AND status <> 'CANCELLED'
  GROUP BY coupon_id
) usage_data ON usage_data.coupon_id = c.coupon_id
SET c.usage_count = COALESCE(usage_data.uses_count, c.usage_count)
WHERE c.coupon_id IN (1,2,3,4);

INSERT INTO payments (order_id, method, status, amount, transaction_reference, paid_at, created_at)
SELECT
  order_id,
  CASE order_id % 4 WHEN 0 THEN 'PIX' WHEN 1 THEN 'CREDIT_CARD' WHEN 2 THEN 'DEBIT_CARD' ELSE 'BANK_SLIP' END,
  CASE WHEN status = 'PENDING' THEN 'PENDING' WHEN status = 'CANCELLED' THEN 'REFUNDED' ELSE 'APPROVED' END,
  total_amount,
  CONCAT('TX-', LPAD(order_id, 8, '0')),
  CASE WHEN status = 'PENDING' THEN NULL ELSE DATE_ADD(placed_at, INTERVAL 15 MINUTE) END,
  placed_at
FROM orders;

INSERT INTO shipments (order_id, carrier, tracking_code, status, estimated_delivery_date, shipped_at, delivered_at, created_at)
SELECT
  order_id,
  CASE order_id % 3 WHEN 0 THEN 'Entrega Sul' WHEN 1 THEN 'Rota Expressa' ELSE 'Logística Brasil' END,
  CONCAT('BR', LPAD(order_id, 10, '0')),
  CASE WHEN status = 'DELIVERED' THEN 'DELIVERED' ELSE 'IN_TRANSIT' END,
  DATE_ADD(DATE(placed_at), INTERVAL 5 DAY),
  DATE_ADD(placed_at, INTERVAL 2 DAY),
  CASE
    WHEN status = 'DELIVERED' THEN DATE_ADD(placed_at, INTERVAL (CASE WHEN order_id % 8 = 0 THEN 8 ELSE 4 END) DAY)
    ELSE NULL
  END,
  placed_at
FROM orders
WHERE status IN ('SHIPPED','DELIVERED');

INSERT INTO returns (order_id, status, requested_at, processed_at, total_refund_amount, notes)
SELECT
  order_id,
  'REFUNDED',
  DATE_ADD(placed_at, INTERVAL 9 DAY),
  DATE_ADD(placed_at, INTERVAL 12 DAY),
  0,
  'Devolução determinística para análise'
FROM orders
WHERE status = 'DELIVERED' AND order_id % 13 = 0;

INSERT INTO return_items (return_id, order_item_id, quantity, reason, condition_on_arrival, refund_amount)
SELECT
  r.return_id,
  oi.order_item_id,
  1,
  CASE r.return_id % 4 WHEN 0 THEN 'DEFECTIVE' WHEN 1 THEN 'REGRET' WHEN 2 THEN 'DAMAGED' ELSE 'WRONG_ITEM' END,
  CASE r.return_id % 3 WHEN 0 THEN 'DAMAGED' WHEN 1 THEN 'OPENED' ELSE 'SEALED' END,
  oi.unit_price
FROM returns r
JOIN order_items oi ON oi.order_item_id = (
  SELECT MIN(selected_item.order_item_id)
  FROM order_items selected_item
  WHERE selected_item.order_id = r.order_id
);

UPDATE returns r
JOIN (SELECT return_id, SUM(refund_amount) AS total FROM return_items GROUP BY return_id) x ON x.return_id = r.return_id
SET r.total_refund_amount = x.total;

INSERT INTO reviews (customer_id, product_id, order_item_id, rating, title, comment, status, created_at)
SELECT
  o.customer_id,
  oi.product_id,
  oi.order_item_id,
  1 + (o.order_id % 5),
  CONCAT('Avaliação ', 1 + (o.order_id % 5), ' estrelas'),
  'Avaliação fictícia criada exclusivamente para o laboratório SQL.',
  'PUBLISHED',
  DATE_ADD(o.placed_at, INTERVAL 15 DAY)
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'DELIVERED' AND o.order_id % 5 = 0
GROUP BY o.order_id, o.customer_id, oi.product_id;

INSERT INTO order_status_history (order_id, old_status, new_status, reason, changed_by, changed_at)
SELECT order_id, NULL, status, 'Estado importado pelo seed determinístico', 'seed', placed_at FROM orders;

INSERT INTO inventory_movements (
  product_id, movement_type, quantity_change, balance_after,
  reference_type, reference_id, reason, created_at, created_by
)
SELECT
  oi.product_id,
  'SALE',
  -oi.quantity,
  150 - SUM(oi.quantity) OVER (PARTITION BY oi.product_id ORDER BY o.placed_at, oi.order_item_id),
  'ORDER',
  o.order_id,
  'Saída associada a pedido do seed',
  o.placed_at,
  'seed'
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE o.status <> 'CANCELLED';

UPDATE inventory i
LEFT JOIN (
  SELECT oi.product_id, SUM(oi.quantity) AS sold_quantity
  FROM order_items oi
  JOIN orders o ON o.order_id = oi.order_id
  WHERE o.status <> 'CANCELLED'
  GROUP BY oi.product_id
) sold ON sold.product_id = i.product_id
SET i.quantity_on_hand = 150 - COALESCE(sold.sold_quantity, 0);

INSERT INTO inventory_movements (
  product_id, movement_type, quantity_change, balance_after,
  reference_type, reference_id, reason, created_at, created_by
)
SELECT
  oi.product_id,
  'RETURN',
  ri.quantity,
  i.quantity_on_hand + SUM(ri.quantity) OVER (PARTITION BY oi.product_id ORDER BY r.processed_at, ri.return_item_id),
  'RETURN',
  r.return_id,
  'Entrada de produto devolvido',
  r.processed_at,
  'seed'
FROM return_items ri
JOIN returns r ON r.return_id = ri.return_id
JOIN order_items oi ON oi.order_item_id = ri.order_item_id
JOIN inventory i ON i.product_id = oi.product_id
WHERE r.status IN ('RECEIVED','REFUNDED');

UPDATE inventory i
JOIN (
  SELECT oi.product_id, SUM(ri.quantity) AS returned_quantity
  FROM return_items ri
  JOIN returns r ON r.return_id = ri.return_id
  JOIN order_items oi ON oi.order_item_id = ri.order_item_id
  WHERE r.status IN ('RECEIVED','REFUNDED')
  GROUP BY oi.product_id
) returned ON returned.product_id = i.product_id
SET i.quantity_on_hand = i.quantity_on_hand + returned.returned_quantity;

INSERT INTO inventory_movements (
  product_id, movement_type, quantity_change, balance_after,
  reference_type, reference_id, reason, created_at, created_by
)
SELECT product_id, 'ADJUSTMENT', CAST(5 AS SIGNED) - CAST(quantity_on_hand AS SIGNED), 5, 'SEED', product_id, 'Ajuste para cenário de estoque baixo', '2026-08-01 08:00:00', 'seed'
FROM inventory
WHERE product_id % 17 = 0 AND quantity_on_hand <> 5;

UPDATE inventory SET quantity_on_hand = 5 WHERE product_id % 17 = 0;

DROP TEMPORARY TABLE seed_numbers;
