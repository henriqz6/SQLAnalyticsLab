SET NAMES utf8mb4;
SET time_zone = '+00:00';

CREATE TABLE customers (
  customer_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  full_name VARCHAR(160) NOT NULL,
  email VARCHAR(190) NOT NULL,
  phone VARCHAR(30) NULL,
  birth_date DATE NULL,
  status ENUM('ACTIVE','INACTIVE','BLOCKED') NOT NULL DEFAULT 'ACTIVE',
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  CONSTRAINT pk_customers PRIMARY KEY (customer_id),
  CONSTRAINT uk_customers_email UNIQUE (email),
  CONSTRAINT ck_customers_email CHECK (email LIKE '%_@_%._%')
) ENGINE=InnoDB;

CREATE TABLE addresses (
  address_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id BIGINT UNSIGNED NOT NULL,
  label VARCHAR(40) NOT NULL DEFAULT 'Principal',
  street VARCHAR(180) NOT NULL,
  number VARCHAR(20) NOT NULL,
  complement VARCHAR(80) NULL,
  district VARCHAR(100) NOT NULL,
  city VARCHAR(100) NOT NULL,
  state CHAR(2) NOT NULL,
  postal_code CHAR(8) NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT pk_addresses PRIMARY KEY (address_id),
  CONSTRAINT fk_addresses_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE,
  CONSTRAINT ck_addresses_state CHECK (state = UPPER(state)),
  CONSTRAINT ck_addresses_postal_code CHECK (postal_code REGEXP '^[0-9]{8}$')
) ENGINE=InnoDB;

CREATE TABLE suppliers (
  supplier_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  legal_name VARCHAR(180) NOT NULL,
  trade_name VARCHAR(140) NOT NULL,
  tax_id CHAR(14) NOT NULL,
  email VARCHAR(190) NOT NULL,
  lead_time_days SMALLINT UNSIGNED NOT NULL DEFAULT 5,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  CONSTRAINT pk_suppliers PRIMARY KEY (supplier_id),
  CONSTRAINT uk_suppliers_tax_id UNIQUE (tax_id),
  CONSTRAINT ck_suppliers_lead_time CHECK (lead_time_days BETWEEN 0 AND 365)
) ENGINE=InnoDB;

CREATE TABLE categories (
  category_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  parent_category_id BIGINT UNSIGNED NULL,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(120) NOT NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_categories PRIMARY KEY (category_id),
  CONSTRAINT uk_categories_slug UNIQUE (slug),
  CONSTRAINT fk_categories_parent FOREIGN KEY (parent_category_id) REFERENCES categories(category_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE products (
  product_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  supplier_id BIGINT UNSIGNED NOT NULL,
  sku VARCHAR(40) NOT NULL,
  name VARCHAR(180) NOT NULL,
  description VARCHAR(600) NULL,
  cost_price DECIMAL(13,2) NOT NULL,
  sale_price DECIMAL(13,2) NOT NULL,
  weight_grams INT UNSIGNED NULL,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  CONSTRAINT pk_products PRIMARY KEY (product_id),
  CONSTRAINT uk_products_sku UNIQUE (sku),
  CONSTRAINT fk_products_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id),
  CONSTRAINT ck_products_cost CHECK (cost_price >= 0),
  CONSTRAINT ck_products_price CHECK (sale_price >= 0),
  CONSTRAINT ck_products_margin CHECK (sale_price >= cost_price)
) ENGINE=InnoDB;

CREATE TABLE product_categories (
  product_id BIGINT UNSIGNED NOT NULL,
  category_id BIGINT UNSIGNED NOT NULL,
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  CONSTRAINT pk_product_categories PRIMARY KEY (product_id, category_id),
  CONSTRAINT fk_product_categories_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
  CONSTRAINT fk_product_categories_category FOREIGN KEY (category_id) REFERENCES categories(category_id)
) ENGINE=InnoDB;

CREATE TABLE product_price_history (
  price_history_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id BIGINT UNSIGNED NOT NULL,
  old_price DECIMAL(13,2) NULL,
  new_price DECIMAL(13,2) NOT NULL,
  changed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  changed_by VARCHAR(100) NOT NULL DEFAULT 'system',
  CONSTRAINT pk_product_price_history PRIMARY KEY (price_history_id),
  CONSTRAINT fk_price_history_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
  CONSTRAINT ck_price_history_values CHECK (new_price >= 0 AND (old_price IS NULL OR old_price >= 0))
) ENGINE=InnoDB;

CREATE TABLE inventory (
  product_id BIGINT UNSIGNED NOT NULL,
  quantity_on_hand INT UNSIGNED NOT NULL DEFAULT 0,
  reserved_quantity INT UNSIGNED NOT NULL DEFAULT 0,
  reorder_point INT UNSIGNED NOT NULL DEFAULT 10,
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  CONSTRAINT pk_inventory PRIMARY KEY (product_id),
  CONSTRAINT fk_inventory_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE,
  CONSTRAINT ck_inventory_reservation CHECK (reserved_quantity <= quantity_on_hand)
) ENGINE=InnoDB;

CREATE TABLE inventory_movements (
  movement_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  product_id BIGINT UNSIGNED NOT NULL,
  movement_type ENUM('INITIAL','PURCHASE','SALE','RETURN','CANCELLATION','ADJUSTMENT') NOT NULL,
  quantity_change INT NOT NULL,
  balance_after INT UNSIGNED NOT NULL,
  reference_type VARCHAR(30) NULL,
  reference_id BIGINT UNSIGNED NULL,
  reason VARCHAR(240) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  created_by VARCHAR(100) NOT NULL DEFAULT 'system',
  CONSTRAINT pk_inventory_movements PRIMARY KEY (movement_id),
  CONSTRAINT fk_inventory_movements_product FOREIGN KEY (product_id) REFERENCES products(product_id),
  CONSTRAINT ck_inventory_change CHECK (quantity_change <> 0)
) ENGINE=InnoDB;

CREATE TABLE coupons (
  coupon_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code VARCHAR(40) NOT NULL,
  discount_type ENUM('PERCENTAGE','FIXED') NOT NULL,
  discount_value DECIMAL(13,2) NOT NULL,
  max_discount_amount DECIMAL(13,2) NULL,
  minimum_order_amount DECIMAL(13,2) NOT NULL DEFAULT 0,
  starts_at DATETIME(6) NOT NULL,
  ends_at DATETIME(6) NOT NULL,
  usage_limit INT UNSIGNED NULL,
  usage_count INT UNSIGNED NOT NULL DEFAULT 0,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT pk_coupons PRIMARY KEY (coupon_id),
  CONSTRAINT uk_coupons_code UNIQUE (code),
  CONSTRAINT ck_coupons_value CHECK (discount_value > 0),
  CONSTRAINT ck_coupons_percentage CHECK (discount_type <> 'PERCENTAGE' OR discount_value <= 100),
  CONSTRAINT ck_coupons_period CHECK (starts_at < ends_at),
  CONSTRAINT ck_coupons_usage CHECK (usage_limit IS NULL OR usage_count <= usage_limit)
) ENGINE=InnoDB;
