-- Заполнение Data Vault

-- Создание расширения для работы с хешами
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Функция для вычисления hash_diff
CREATE OR REPLACE FUNCTION calculate_hash_diff(data_text TEXT)
RETURNS VARCHAR(64) AS $$
BEGIN
    RETURN encode(digest(data_text, 'sha256'), 'hex');
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION populate_data_vault()
RETURNS void AS $$
BEGIN
    -- Заполнение Hubs
    INSERT INTO hub_customer (customer_id, load_date, record_source)
    SELECT DISTINCT customer_id, created_at, 'SOURCE_SYSTEM'
    FROM customers
    ON CONFLICT (customer_id) DO NOTHING;

    INSERT INTO hub_product (product_id, load_date, record_source)
    SELECT DISTINCT product_id, created_at, 'SOURCE_SYSTEM'
    FROM products
    ON CONFLICT (product_id) DO NOTHING;

    INSERT INTO hub_order (order_id, load_date, record_source)
    SELECT DISTINCT order_id, created_at, 'SOURCE_SYSTEM'
    FROM orders
    ON CONFLICT (order_id) DO NOTHING;

    INSERT INTO hub_order_status (status_id, load_date, record_source)
    SELECT DISTINCT status_id, created_at, 'SOURCE_SYSTEM'
    FROM order_statuses
    ON CONFLICT (status_id) DO NOTHING;

    -- Заполнение Satellites с поддержкой истории
    -- sat_customer
    -- Закрываем старые версии для измененных записей
    UPDATE sat_customer sc
    SET load_end_date = c.updated_at
    FROM customers c
    JOIN hub_customer h ON c.customer_id = h.customer_id
    WHERE sc.customer_hub_key = h.customer_hub_key
    AND sc.load_end_date IS NULL
    AND c.updated_at IS NOT NULL
    AND c.updated_at > c.created_at
    AND sc.load_date < c.updated_at
    AND sc.hash_diff != calculate_hash_diff(c.name || '|' || c.email || '|' || COALESCE(c.phone, '') || '|' || COALESCE(c.address, ''));

    -- Вставляем новые версии
    INSERT INTO sat_customer (customer_hub_key, name, email, phone, address, load_date, record_source, hash_diff)
    SELECT h.customer_hub_key, c.name, c.email, c.phone, c.address, 
           COALESCE(c.updated_at, c.created_at), 'SOURCE_SYSTEM',
           calculate_hash_diff(c.name || '|' || c.email || '|' || COALESCE(c.phone, '') || '|' || COALESCE(c.address, ''))
    FROM customers c
    JOIN hub_customer h ON c.customer_id = h.customer_id
    WHERE NOT EXISTS (
        SELECT 1 FROM sat_customer s 
        WHERE s.customer_hub_key = h.customer_hub_key 
        AND s.hash_diff = calculate_hash_diff(c.name || '|' || c.email || '|' || COALESCE(c.phone, '') || '|' || COALESCE(c.address, ''))
        AND s.load_end_date IS NULL
    );

    -- sat_product
    -- Закрываем старые версии для измененных записей
    UPDATE sat_product sp
    SET load_end_date = p.updated_at
    FROM products p
    JOIN hub_product h ON p.product_id = h.product_id
    WHERE sp.product_hub_key = h.product_hub_key
    AND sp.load_end_date IS NULL
    AND p.updated_at IS NOT NULL
    AND p.updated_at > p.created_at
    AND sp.load_date < p.updated_at
    AND sp.hash_diff != calculate_hash_diff(p.product_name || '|' || p.category || '|' || p.price::TEXT);

    -- Вставляем новые версии
    INSERT INTO sat_product (product_hub_key, product_name, category, price, load_date, record_source, hash_diff)
    SELECT h.product_hub_key, p.product_name, p.category, p.price,
           COALESCE(p.updated_at, p.created_at), 'SOURCE_SYSTEM',
           calculate_hash_diff(p.product_name || '|' || p.category || '|' || p.price::TEXT)
    FROM products p
    JOIN hub_product h ON p.product_id = h.product_id
    WHERE NOT EXISTS (
        SELECT 1 FROM sat_product s 
        WHERE s.product_hub_key = h.product_hub_key 
        AND s.hash_diff = calculate_hash_diff(p.product_name || '|' || p.category || '|' || p.price::TEXT)
        AND s.load_end_date IS NULL
    );

    -- sat_order
    -- Вставляем новые версии (заказы обычно не изменяются после создания)
    INSERT INTO sat_order (order_hub_key, order_date, total_amount, load_date, record_source, hash_diff)
    SELECT h.order_hub_key, o.order_date, o.total_amount, o.created_at, 'SOURCE_SYSTEM',
           calculate_hash_diff(o.order_date::TEXT || '|' || o.total_amount::TEXT)
    FROM orders o
    JOIN hub_order h ON o.order_id = h.order_id
    WHERE NOT EXISTS (
        SELECT 1 FROM sat_order s 
        WHERE s.order_hub_key = h.order_hub_key 
        AND s.hash_diff = calculate_hash_diff(o.order_date::TEXT || '|' || o.total_amount::TEXT)
        AND s.load_end_date IS NULL
    );

    -- sat_order_status
    -- Вставляем новые версии (статусы обычно не изменяются после создания)
    INSERT INTO sat_order_status (status_hub_key, status_name, description, load_date, record_source, hash_diff)
    SELECT h.status_hub_key, os.status_name, os.description, os.created_at, 'SOURCE_SYSTEM',
           calculate_hash_diff(os.status_name || '|' || COALESCE(os.description, ''))
    FROM order_statuses os
    JOIN hub_order_status h ON os.status_id = h.status_id
    WHERE NOT EXISTS (
        SELECT 1 FROM sat_order_status s 
        WHERE s.status_hub_key = h.status_hub_key 
        AND s.hash_diff = calculate_hash_diff(os.status_name || '|' || COALESCE(os.description, ''))
        AND s.load_end_date IS NULL
    );

    -- Заполнение Links
    INSERT INTO link_order_customer (order_hub_key, customer_hub_key, load_date, record_source)
    SELECT ho.order_hub_key, hc.customer_hub_key, o.created_at, 'SOURCE_SYSTEM'
    FROM orders o
    JOIN hub_order ho ON o.order_id = ho.order_id
    JOIN hub_customer hc ON o.customer_id = hc.customer_id
    ON CONFLICT (order_hub_key, customer_hub_key) DO NOTHING;

    INSERT INTO link_order_status (order_hub_key, status_hub_key, load_date, record_source)
    SELECT ho.order_hub_key, hs.status_hub_key, o.created_at, 'SOURCE_SYSTEM'
    FROM orders o
    JOIN hub_order ho ON o.order_id = ho.order_id
    JOIN hub_order_status hs ON o.status_id = hs.status_id
    ON CONFLICT (order_hub_key, status_hub_key) DO NOTHING;

    -- Заполнение link_order_product
    -- Примечание: один заказ может содержать один продукт несколько раз (разные позиции)
    INSERT INTO link_order_product (order_hub_key, product_hub_key, quantity, price, load_date, record_source)
    SELECT ho.order_hub_key, hp.product_hub_key, oi.quantity, oi.price, oi.created_at, 'SOURCE_SYSTEM'
    FROM order_items oi
    JOIN orders o ON oi.order_id = o.order_id
    JOIN hub_order ho ON o.order_id = ho.order_id
    JOIN hub_product hp ON oi.product_id = hp.product_id
    WHERE NOT EXISTS (
        SELECT 1 FROM link_order_product lop
        WHERE lop.order_hub_key = ho.order_hub_key
        AND lop.product_hub_key = hp.product_hub_key
        AND lop.quantity = oi.quantity
        AND lop.price = oi.price
        AND lop.load_date = oi.created_at
    );

    RAISE NOTICE 'Data Vault population completed';
END;
$$ LANGUAGE plpgsql;

SELECT populate_data_vault();

