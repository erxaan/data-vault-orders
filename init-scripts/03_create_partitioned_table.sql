-- Партиционированная таблица для заказов
-- Соответствует схеме Data Vault: использует order_hub_key вместо order_id

CREATE TABLE IF NOT EXISTS orders_partitioned (
    order_hub_key BIGINT NOT NULL REFERENCES hub_order(order_hub_key),
    customer_hub_key BIGINT NOT NULL REFERENCES hub_customer(customer_hub_key),
    status_hub_key BIGINT NOT NULL REFERENCES hub_order_status(status_hub_key),
    order_date DATE NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    load_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    record_source VARCHAR(50) NOT NULL DEFAULT 'SOURCE_SYSTEM',
    PRIMARY KEY (order_hub_key, order_date)
) PARTITION BY RANGE (order_date);

-- Партиции по годам
CREATE TABLE IF NOT EXISTS orders_2023 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2023-01-01') TO ('2024-01-01');

CREATE TABLE IF NOT EXISTS orders_2024 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2024-01-01') TO ('2025-01-01');

CREATE TABLE IF NOT EXISTS orders_2025 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2025-01-01') TO ('2026-01-01');

CREATE TABLE IF NOT EXISTS orders_2026 PARTITION OF orders_partitioned
    FOR VALUES FROM ('2026-01-01') TO ('2027-01-01');

-- Индексы для партиционированной таблицы
CREATE INDEX IF NOT EXISTS idx_orders_partitioned_order_hub_key ON orders_partitioned(order_hub_key);
CREATE INDEX IF NOT EXISTS idx_orders_partitioned_customer ON orders_partitioned(customer_hub_key);
CREATE INDEX IF NOT EXISTS idx_orders_partitioned_status ON orders_partitioned(status_hub_key);
CREATE INDEX IF NOT EXISTS idx_orders_partitioned_date ON orders_partitioned(order_date);
CREATE INDEX IF NOT EXISTS idx_orders_partitioned_total ON orders_partitioned(total_amount);
CREATE INDEX IF NOT EXISTS idx_orders_partitioned_load_date ON orders_partitioned(load_date);

