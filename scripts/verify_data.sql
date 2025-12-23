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

-- Проверка партиционированной таблицы sat_order
SELECT 'Partitioned Table (sat_order)' AS section;
SELECT 
    COUNT(*) AS total_orders,
    COUNT(DISTINCT order_hub_key) AS unique_orders,
    SUM(total_amount) AS total_revenue
FROM sat_order
WHERE load_end_date IS NULL;

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
WHERE loc.order_hub_key IS NULL
UNION ALL
SELECT 'hub_order -> link_order_status',
    COUNT(*)
FROM hub_order ho
LEFT JOIN link_order_status los ON ho.order_hub_key = los.order_hub_key
WHERE los.order_hub_key IS NULL
UNION ALL
SELECT 'hub_order -> link_order_product',
    COUNT(*)
FROM hub_order ho
LEFT JOIN link_order_product lop ON ho.order_hub_key = lop.order_hub_key
WHERE lop.order_hub_key IS NULL;

-- Проверка целостности партиционированной sat_order с Data Vault
SELECT 'Partitioned Table Integrity' AS section;
SELECT 
    'sat_order -> hub_order' AS check_name,
    COUNT(*) AS orphaned_records
FROM sat_order so
LEFT JOIN hub_order ho ON so.order_hub_key = ho.order_hub_key
WHERE so.load_end_date IS NULL
AND ho.order_hub_key IS NULL;

-- Проверка партиций sat_order
SELECT 'Partitions' AS section;
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE tablename LIKE 'sat_order_%'
ORDER BY tablename;

-- Проверка распределения данных по партициям
SELECT 'Partition Distribution' AS section;
SELECT 
    'sat_order_2023' AS partition,
    COUNT(*) AS orders_count
FROM sat_order
WHERE order_date >= '2023-01-01' AND order_date < '2024-01-01'
AND load_end_date IS NULL
UNION ALL
SELECT 'sat_order_2024', COUNT(*)
FROM sat_order
WHERE order_date >= '2024-01-01' AND order_date < '2025-01-01'
AND load_end_date IS NULL
UNION ALL
SELECT 'sat_order_2025', COUNT(*)
FROM sat_order
WHERE order_date >= '2025-01-01' AND order_date < '2026-01-01'
AND load_end_date IS NULL
UNION ALL
SELECT 'sat_order_2026', COUNT(*)
FROM sat_order
WHERE order_date >= '2026-01-01' AND order_date < '2027-01-01'
AND load_end_date IS NULL;

