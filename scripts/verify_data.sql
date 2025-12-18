-- Проверка целостности данных

-- Проверка Hubs
SELECT 'Hubs' AS section;
SELECT 
    'hub_customer' AS table_name,
    COUNT(*) AS count
FROM hub_customer
UNION ALL
SELECT 'hub_product', COUNT(*) FROM hub_product
UNION ALL
SELECT 'hub_order', COUNT(*) FROM hub_order
UNION ALL
SELECT 'hub_order_status', COUNT(*) FROM hub_order_status;

-- Проверка Satellites
SELECT 'Satellites' AS section;
SELECT 
    'sat_customer' AS table_name,
    COUNT(*) AS count
FROM sat_customer
UNION ALL
SELECT 'sat_product', COUNT(*) FROM sat_product
UNION ALL
SELECT 'sat_order', COUNT(*) FROM sat_order
UNION ALL
SELECT 'sat_order_status', COUNT(*) FROM sat_order_status;

-- Проверка Links
SELECT 'Links' AS section;
SELECT 
    'link_order_customer' AS table_name,
    COUNT(*) AS count
FROM link_order_customer
UNION ALL
SELECT 'link_order_status', COUNT(*) FROM link_order_status
UNION ALL
SELECT 'link_order_product', COUNT(*) FROM link_order_product;

-- Проверка партиционированной таблицы
SELECT 'Partitioned Table' AS section;
SELECT 
    COUNT(*) AS total_orders,
    COUNT(DISTINCT customer_hub_key) AS unique_customers,
    SUM(total_amount) AS total_revenue
FROM orders_partitioned;

-- Проверка целостности ссылок
SELECT 'Data Integrity' AS section;
SELECT 
    'hub_customer -> sat_customer' AS check_name,
    COUNT(*) AS orphaned_records
FROM hub_customer hc
LEFT JOIN sat_customer sc ON hc.customer_hub_key = sc.customer_hub_key
WHERE sc.customer_hub_key IS NULL
UNION ALL
SELECT 'hub_order -> link_order_customer',
    COUNT(*)
FROM hub_order ho
LEFT JOIN link_order_customer loc ON ho.order_hub_key = loc.order_hub_key
WHERE loc.order_hub_key IS NULL;

-- Проверка партиций
SELECT 'Partitions' AS section;
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE tablename LIKE 'orders_%'
ORDER BY tablename;

