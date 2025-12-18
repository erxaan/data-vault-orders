-- Тестирование партиционированной таблицы

-- Тест 1: Вставка данных в разные партиции
INSERT INTO orders_partitioned (order_id, customer_hub_key, status_hub_key, order_date, total_amount)
VALUES (999, 1, 1, '2025-12-18', 50000.00);

INSERT INTO orders_partitioned (order_id, customer_hub_key, status_hub_key, order_date, total_amount)
VALUES (998, 2, 2, '2024-06-15', 35000.00);

SELECT 
    'Вставка выполнена' AS test,
    COUNT(*) AS records
FROM orders_partitioned
WHERE order_id IN (999, 998);

-- Тест 2: Запрос данных из конкретной партиции
SELECT 
    'Заказы за 2025 год' AS test,
    COUNT(*) AS count,
    SUM(total_amount) AS total
FROM orders_partitioned
WHERE order_date >= '2025-01-01' AND order_date < '2026-01-01';

-- Тест 3: Запрос с JOIN через Data Vault
SELECT 
    sc.name AS customer_name,
    op.order_date,
    op.total_amount,
    sos.status_name
FROM orders_partitioned op
JOIN hub_order ho ON op.order_id = ho.order_id
JOIN link_order_customer loc ON ho.order_hub_key = loc.order_hub_key
JOIN sat_customer sc ON loc.customer_hub_key = sc.customer_hub_key
JOIN link_order_status los ON ho.order_hub_key = los.order_hub_key
JOIN sat_order_status sos ON los.status_hub_key = sos.status_hub_key
WHERE op.order_date >= '2025-12-01'
  AND sc.load_end_date IS NULL
ORDER BY op.order_date DESC
LIMIT 5;

-- Тест 4: Проверка использования партиций (EXPLAIN)
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders_partitioned
WHERE order_date BETWEEN '2025-12-01' AND '2025-12-31';

