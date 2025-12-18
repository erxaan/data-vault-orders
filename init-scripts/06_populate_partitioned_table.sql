-- Заполнение партиционированной таблицы

CREATE OR REPLACE FUNCTION populate_partitioned_orders()
RETURNS void AS $$
DECLARE
    rec RECORD;
    processed_count INTEGER := 0;
BEGIN
    FOR rec IN
        SELECT o.order_id, ho.order_hub_key, hs.status_hub_key, o.order_date, o.total_amount
        FROM orders o
        JOIN hub_order ho ON o.order_id = ho.order_id
        JOIN hub_order_status hs ON o.status_id = hs.status_id
        WHERE NOT EXISTS (
            SELECT 1 FROM orders_partitioned op WHERE op.order_id = o.order_id
        )
    LOOP
        INSERT INTO orders_partitioned (order_id, customer_hub_key, status_hub_key, order_date, total_amount)
        SELECT rec.order_id, loc.customer_hub_key, rec.status_hub_key, rec.order_date, rec.total_amount
        FROM link_order_customer loc
        WHERE loc.order_hub_key = rec.order_hub_key
        LIMIT 1;
        
        processed_count := processed_count + 1;
    END LOOP;

    RAISE NOTICE 'Partitioned orders population completed. Processed: %', processed_count;
END;
$$ LANGUAGE plpgsql;

SELECT populate_partitioned_orders();

