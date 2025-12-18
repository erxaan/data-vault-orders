SELECT populate_data_vault();

SELECT 
    'Hubs' AS type,
    COUNT(*) AS count
FROM hub_customer
UNION ALL
SELECT 'Hubs', COUNT(*) FROM hub_product
UNION ALL
SELECT 'Hubs', COUNT(*) FROM hub_order
UNION ALL
SELECT 'Hubs', COUNT(*) FROM hub_order_status
UNION ALL
SELECT 'Satellites', COUNT(*) FROM sat_customer
UNION ALL
SELECT 'Satellites', COUNT(*) FROM sat_product
UNION ALL
SELECT 'Satellites', COUNT(*) FROM sat_order
UNION ALL
SELECT 'Links', COUNT(*) FROM link_order_customer
UNION ALL
SELECT 'Links', COUNT(*) FROM link_order_status
UNION ALL
SELECT 'Links', COUNT(*) FROM link_order_product;

