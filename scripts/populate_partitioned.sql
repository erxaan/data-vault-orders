SELECT populate_partitioned_orders();

SELECT 
    'Всего заказов' AS description,
    COUNT(*) AS count
FROM orders_partitioned
UNION ALL
SELECT 'Заказы 2025', COUNT(*) FROM orders_partitioned WHERE order_date >= '2025-01-01'
UNION ALL
SELECT 'Заказы 2024', COUNT(*) FROM orders_partitioned WHERE order_date >= '2024-01-01' AND order_date < '2025-01-01';

SELECT 
    order_date,
    COUNT(*) AS orders_count,
    SUM(total_amount) AS total_sum
FROM orders_partitioned
GROUP BY order_date
ORDER BY order_date DESC
LIMIT 10;

