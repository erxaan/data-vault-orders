-- Тестирование партиционированной таблицы
-- Использует схему Data Vault с order_hub_key

-- Тест 1: Вставка данных в разные партиции через Data Vault
-- Получаем hub_key из существующих данных для теста
INSERT INTO orders_partitioned (
    order_hub_key, 
    customer_hub_key, 
    status_hub_key, 
    order_date, 
    total_amount,
    load_date,
    record_source
)
SELECT 
    ho.order_hub_key,
    loc.customer_hub_key,
    los.status_hub_key,
    '2025-12-18'::DATE,
    50000.00,
    CURRENT_TIMESTAMP,
    'TEST_SYSTEM'
FROM hub_order ho
JOIN link_order_customer loc ON ho.order_hub_key = loc.order_hub_key
JOIN link_order_status los ON ho.order_hub_key = los.order_hub_key
WHERE ho.order_hub_key = (SELECT MIN(order_hub_key) FROM hub_order)
AND NOT EXISTS (
    SELECT 1 FROM orders_partitioned op 
    WHERE op.order_hub_key = ho.order_hub_key 
    AND op.order_date = '2025-12-18'::DATE
)
LIMIT 1;

SELECT 
    'Вставка выполнена' AS test,
    COUNT(*) AS records
FROM orders_partitioned
WHERE order_date IN ('2025-12-18', '2024-06-15');

-- Тест 2: Запрос данных из конкретной партиции
SELECT 
    'Заказы за 2025 год' AS test,
    COUNT(*) AS count,
    SUM(total_amount) AS total
FROM orders_partitioned
WHERE order_date >= '2025-01-01' AND order_date < '2026-01-01';

-- Тест 3: Запрос с JOIN через Data Vault (упрощенный, так как hub_key уже в партиции)
SELECT 
    sc.name AS customer_name,
    op.order_date,
    op.total_amount,
    sos.status_name
FROM orders_partitioned op
JOIN sat_customer sc ON op.customer_hub_key = sc.customer_hub_key
JOIN sat_order_status sos ON op.status_hub_key = sos.status_hub_key
WHERE op.order_date >= '2025-12-01'
  AND sc.load_end_date IS NULL
  AND sos.load_end_date IS NULL
ORDER BY op.order_date DESC
LIMIT 5;

-- Тест 4: Проверка использования партиций (EXPLAIN)
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders_partitioned
WHERE order_date BETWEEN '2025-12-01' AND '2025-12-31';

