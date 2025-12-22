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

-- Проверка целостности партиционированной таблицы с Data Vault
SELECT 'Partitioned Table Integrity' AS section;
SELECT 
    'orders_partitioned -> hub_order' AS check_name,
    COUNT(*) AS orphaned_records
FROM orders_partitioned op
LEFT JOIN hub_order ho ON op.order_hub_key = ho.order_hub_key
WHERE ho.order_hub_key IS NULL
UNION ALL
SELECT 'orders_partitioned -> hub_customer',
    COUNT(*)
FROM orders_partitioned op
LEFT JOIN hub_customer hc ON op.customer_hub_key = hc.customer_hub_key
WHERE hc.customer_hub_key IS NULL
UNION ALL
SELECT 'orders_partitioned -> hub_order_status',
    COUNT(*)
FROM orders_partitioned op
LEFT JOIN hub_order_status hos ON op.status_hub_key = hos.status_hub_key
WHERE hos.status_hub_key IS NULL;

-- Проверка соответствия данных между Data Vault и orders_partitioned
SELECT 'Data Consistency' AS section;
SELECT 
    'sat_order vs orders_partitioned (count)' AS check_name,
    ABS((SELECT COUNT(*) FROM sat_order WHERE load_end_date IS NULL) - 
        (SELECT COUNT(*) FROM orders_partitioned)) AS difference
UNION ALL
SELECT 'sat_order vs orders_partitioned (total_amount)',
    ABS((SELECT COALESCE(SUM(total_amount), 0) FROM sat_order WHERE load_end_date IS NULL) - 
        (SELECT COALESCE(SUM(total_amount), 0) FROM orders_partitioned))::DECIMAL(10,2);

-- Проверка партиций
SELECT 'Partitions' AS section;
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE tablename LIKE 'orders_%'
ORDER BY tablename;

