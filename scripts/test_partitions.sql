-- Тестирование партиционированной таблицы sat_order

-- Тест 1: Вставка данных в разные партиции
INSERT INTO sat_order (order_hub_key, order_date, total_amount, load_date, record_source, hash_diff)
SELECT 
    ho.order_hub_key,
    '2025-12-18'::DATE,
    50000.00,
    CURRENT_TIMESTAMP,
    'TEST_SYSTEM',
    calculate_hash_diff('2025-12-18|50000.00')
FROM hub_order ho
WHERE ho.order_hub_key = (SELECT MIN(order_hub_key) FROM hub_order)
AND NOT EXISTS (
    SELECT 1 FROM sat_order so 
    WHERE so.order_hub_key = ho.order_hub_key 
    AND so.order_date = '2025-12-18'::DATE
    AND so.load_end_date IS NULL
)
LIMIT 1;

SELECT 
    'Вставка выполнена' AS test,
    COUNT(*) AS records
FROM sat_order
WHERE order_date IN ('2025-12-18', '2024-06-15')
AND load_end_date IS NULL;

-- Тест 2: Запрос данных из конкретной партиции
SELECT 
    'Заказы за 2025 год' AS test,
    COUNT(*) AS count,
    SUM(total_amount) AS total
FROM sat_order
WHERE order_date >= '2025-01-01' AND order_date < '2026-01-01'
AND load_end_date IS NULL;

-- Тест 3: Запрос с JOIN через Data Vault
SELECT 
    sc.name AS customer_name,
    so.order_date,
    so.total_amount,
    sos.status_name
FROM sat_order so
JOIN hub_order ho ON so.order_hub_key = ho.order_hub_key
JOIN link_order_customer loc ON ho.order_hub_key = loc.order_hub_key
JOIN sat_customer sc ON loc.customer_hub_key = sc.customer_hub_key
JOIN link_order_status los ON ho.order_hub_key = los.order_hub_key
JOIN sat_order_status sos ON los.status_hub_key = sos.status_hub_key
WHERE so.order_date >= '2025-12-01'
  AND so.load_end_date IS NULL
  AND sc.load_end_date IS NULL
  AND sos.load_end_date IS NULL
ORDER BY so.order_date DESC
LIMIT 5;

-- Тест 4: Проверка использования партиций (EXPLAIN)
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM sat_order
WHERE order_date BETWEEN '2025-12-01' AND '2025-12-31'
AND load_end_date IS NULL;

-- Тест 5: Запрос "Сколько заказов было в 2025 году" (как в требовании)
SELECT 
    'Заказы в 2025 году' AS description,
    COUNT(*) AS orders_count,
    SUM(total_amount) AS total_amount
FROM sat_order
WHERE order_date >= '2025-01-01' AND order_date < '2026-01-01'
AND load_end_date IS NULL;
