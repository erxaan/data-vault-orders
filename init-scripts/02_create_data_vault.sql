-- Data Vault схема

-- Hubs (Хабы)
CREATE TABLE IF NOT EXISTS hub_customer (
    customer_hub_key BIGSERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(50) NOT NULL DEFAULT 'SOURCE_SYSTEM',
    CONSTRAINT uk_hub_customer_id UNIQUE (customer_id)
);

CREATE TABLE IF NOT EXISTS hub_product (
    product_hub_key BIGSERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(50) NOT NULL DEFAULT 'SOURCE_SYSTEM',
    CONSTRAINT uk_hub_product_id UNIQUE (product_id)
);

CREATE TABLE IF NOT EXISTS hub_order (
    order_hub_key BIGSERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(50) NOT NULL DEFAULT 'SOURCE_SYSTEM',
    CONSTRAINT uk_hub_order_id UNIQUE (order_id)
);

CREATE TABLE IF NOT EXISTS hub_order_status (
    status_hub_key BIGSERIAL PRIMARY KEY,
    status_id INTEGER NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(50) NOT NULL DEFAULT 'SOURCE_SYSTEM',
    CONSTRAINT uk_hub_status_id UNIQUE (status_id)
);

-- Satellites (Сателлиты)
CREATE TABLE IF NOT EXISTS sat_customer (
    customer_sat_key BIGSERIAL PRIMARY KEY,
    customer_hub_key BIGINT NOT NULL REFERENCES hub_customer(customer_hub_key),
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50),
    address TEXT,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_end_date TIMESTAMP,
    record_source VARCHAR(50) NOT NULL DEFAULT 'SOURCE_SYSTEM',
    hash_diff VARCHAR(64)
);

CREATE TABLE IF NOT EXISTS sat_product (
    product_sat_key BIGSERIAL PRIMARY KEY,
    product_hub_key BIGINT NOT NULL REFERENCES hub_product(product_hub_key),
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_end_date TIMESTAMP,
    record_source VARCHAR(50) NOT NULL DEFAULT 'SOURCE_SYSTEM',
    hash_diff VARCHAR(64)
);

-- Партиционированная таблица sat_order по дате заказа
-- Создаем последовательность для order_sat_key
CREATE SEQUENCE IF NOT EXISTS sat_order_order_sat_key_seq;

CREATE TABLE IF NOT EXISTS sat_order (
    order_sat_key BIGINT NOT NULL DEFAULT nextval('sat_order_order_sat_key_seq'),
    order_hub_key BIGINT NOT NULL REFERENCES hub_order(order_hub_key),
    order_date DATE NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_end_date TIMESTAMP,
    record_source VARCHAR(50) NOT NULL DEFAULT 'SOURCE_SYSTEM',
    hash_diff VARCHAR(64),
    PRIMARY KEY (order_sat_key, order_date)
) PARTITION BY RANGE (order_date);

-- Партиции по годам
CREATE TABLE IF NOT EXISTS sat_order_2023 PARTITION OF sat_order
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE IF NOT EXISTS sat_order_2024 PARTITION OF sat_order
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE IF NOT EXISTS sat_order_2025 PARTITION OF sat_order
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE IF NOT EXISTS sat_order_2026 PARTITION OF sat_order
    FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

CREATE TABLE IF NOT EXISTS sat_order_status (
    status_sat_key BIGSERIAL PRIMARY KEY,
    status_hub_key BIGINT NOT NULL REFERENCES hub_order_status(status_hub_key),
    status_name VARCHAR(50) NOT NULL,
    description TEXT,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    load_end_date TIMESTAMP,
    record_source VARCHAR(50) NOT NULL DEFAULT 'SOURCE_SYSTEM',
    hash_diff VARCHAR(64)
);

-- Links (Линки)
CREATE TABLE IF NOT EXISTS link_order_customer (
    order_customer_link_key BIGSERIAL PRIMARY KEY,
    order_hub_key BIGINT NOT NULL REFERENCES hub_order(order_hub_key),
    customer_hub_key BIGINT NOT NULL REFERENCES hub_customer(customer_hub_key),
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(50) NOT NULL DEFAULT 'SOURCE_SYSTEM',
    CONSTRAINT uk_link_order_customer UNIQUE (order_hub_key, customer_hub_key)
);

CREATE TABLE IF NOT EXISTS link_order_status (
    order_status_link_key BIGSERIAL PRIMARY KEY,
    order_hub_key BIGINT NOT NULL REFERENCES hub_order(order_hub_key),
    status_hub_key BIGINT NOT NULL REFERENCES hub_order_status(status_hub_key),
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(50) NOT NULL DEFAULT 'SOURCE_SYSTEM',
    CONSTRAINT uk_link_order_status UNIQUE (order_hub_key, status_hub_key)
);

CREATE TABLE IF NOT EXISTS link_order_product (
    order_product_link_key BIGSERIAL PRIMARY KEY,
    order_hub_key BIGINT NOT NULL REFERENCES hub_order(order_hub_key),
    product_hub_key BIGINT NOT NULL REFERENCES hub_product(product_hub_key),
    quantity INTEGER NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(50) NOT NULL DEFAULT 'SOURCE_SYSTEM'
    -- Убрал UNIQUE constraint, потому что один заказ может содержать продукт несколько раз
    -- Уникальность через PRIMARY KEY (order_product_link_key)
);

-- Индексы для Hubs
CREATE INDEX IF NOT EXISTS idx_hub_customer_load_date ON hub_customer(load_date);
CREATE INDEX IF NOT EXISTS idx_hub_product_load_date ON hub_product(load_date);
CREATE INDEX IF NOT EXISTS idx_hub_order_load_date ON hub_order(load_date);
CREATE INDEX IF NOT EXISTS idx_hub_status_load_date ON hub_order_status(load_date);

-- Индексы для Satellites
CREATE INDEX IF NOT EXISTS idx_sat_customer_hub_key ON sat_customer(customer_hub_key, load_date);
CREATE INDEX IF NOT EXISTS idx_sat_product_hub_key ON sat_product(product_hub_key, load_date);
-- Индексы для партиционированной sat_order
CREATE INDEX IF NOT EXISTS idx_sat_order_hub_key ON sat_order(order_hub_key, load_date);
CREATE INDEX IF NOT EXISTS idx_sat_order_date ON sat_order(order_date);
CREATE INDEX IF NOT EXISTS idx_sat_order_load_date ON sat_order(load_date);
CREATE INDEX IF NOT EXISTS idx_sat_status_hub_key ON sat_order_status(status_hub_key, load_date);

-- Индексы для Links
CREATE INDEX IF NOT EXISTS idx_link_order_customer_order ON link_order_customer(order_hub_key);
CREATE INDEX IF NOT EXISTS idx_link_order_customer_customer ON link_order_customer(customer_hub_key);
CREATE INDEX IF NOT EXISTS idx_link_order_status_order ON link_order_status(order_hub_key);
CREATE INDEX IF NOT EXISTS idx_link_order_status_status ON link_order_status(status_hub_key);
CREATE INDEX IF NOT EXISTS idx_link_order_product_order ON link_order_product(order_hub_key);
CREATE INDEX IF NOT EXISTS idx_link_order_product_product ON link_order_product(product_hub_key);

