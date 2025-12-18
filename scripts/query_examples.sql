-- Примеры запросов для Data Vault

-- Заказы с клиентами через Data Vault
SELECT 
    sc.name AS customer_name,
    sc.email,
    so.order_date,
    so.total_amount,
    sos.status_name
FROM hub_order ho
JOIN sat_order so ON ho.order_hub_key = so.order_hub_key
JOIN link_order_customer loc ON ho.order_hub_key = loc.order_hub_key
JOIN sat_customer sc ON loc.customer_hub_key = sc.customer_hub_key
JOIN link_order_status los ON ho.order_hub_key = los.order_hub_key
JOIN sat_order_status sos ON los.status_hub_key = sos.status_hub_key
WHERE so.load_end_date IS NULL
ORDER BY so.order_date DESC;

-- Продукты в заказах
SELECT 
    sp.product_name,
    sp.category,
    sp.price,
    lop.quantity,
    lop.price AS item_price,
    so.order_date
FROM link_order_product lop
JOIN sat_product sp ON lop.product_hub_key = sp.product_hub_key
JOIN hub_order ho ON lop.order_hub_key = ho.order_hub_key
JOIN sat_order so ON ho.order_hub_key = so.order_hub_key
WHERE sp.load_end_date IS NULL
ORDER BY so.order_date DESC;

-- Статистика по клиентам
SELECT 
    sc.name,
    COUNT(DISTINCT ho.order_hub_key) AS orders_count,
    SUM(so.total_amount) AS total_spent
FROM hub_customer hc
JOIN sat_customer sc ON hc.customer_hub_key = sc.customer_hub_key
JOIN link_order_customer loc ON hc.customer_hub_key = loc.customer_hub_key
JOIN hub_order ho ON loc.order_hub_key = ho.order_hub_key
JOIN sat_order so ON ho.order_hub_key = so.order_hub_key
WHERE sc.load_end_date IS NULL AND so.load_end_date IS NULL
GROUP BY sc.customer_sat_key, sc.name
ORDER BY total_spent DESC;

-- Запрос из партиционированной таблицы с фильтром по дате
SELECT 
    op.order_date,
    COUNT(*) AS orders_count,
    SUM(op.total_amount) AS daily_total
FROM orders_partitioned op
WHERE op.order_date >= '2025-12-01'
GROUP BY op.order_date
ORDER BY op.order_date DESC;

