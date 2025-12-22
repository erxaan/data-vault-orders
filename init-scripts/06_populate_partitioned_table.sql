-- Заполнение партиционированной таблицы
-- Соответствует схеме Data Vault: использует order_hub_key и получает данные через линки

CREATE OR REPLACE FUNCTION populate_partitioned_orders()
RETURNS void AS $$
DECLARE
    processed_count INTEGER;
BEGIN
    -- Вставляем все заказы одним запросом
    -- Используем order_hub_key из Data Vault и получаем данные через линки и сателлиты
    INSERT INTO orders_partitioned (
        order_hub_key, 
        customer_hub_key, 
        status_hub_key, 
        order_date, 
        total_amount,
        load_date,
        record_source
    )
    SELECT DISTINCT
        ho.order_hub_key,
        loc.customer_hub_key,
        los.status_hub_key,
        so.order_date,
        so.total_amount,
        so.load_date,
        so.record_source
    FROM hub_order ho
    JOIN sat_order so ON ho.order_hub_key = so.order_hub_key
    JOIN link_order_customer loc ON ho.order_hub_key = loc.order_hub_key
    JOIN link_order_status los ON ho.order_hub_key = los.order_hub_key
    WHERE so.load_end_date IS NULL  -- Только актуальные версии
    AND NOT EXISTS (
        SELECT 1 
        FROM orders_partitioned op 
        WHERE op.order_hub_key = ho.order_hub_key 
        AND op.order_date = so.order_date
    );

    GET DIAGNOSTICS processed_count = ROW_COUNT;
    RAISE NOTICE 'Partitioned orders population completed. Processed: %', processed_count;
END;
$$ LANGUAGE plpgsql;

SELECT populate_partitioned_orders();

