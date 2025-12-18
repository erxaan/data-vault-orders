-- Тестовые данные

INSERT INTO order_statuses (status_id, status_name, description, created_at) VALUES
(1, 'Новый', 'Заказ создан', '2025-11-01 10:00:00'),
(2, 'Обработка', 'Заказ обрабатывается', '2025-11-01 10:00:00'),
(3, 'Отправлен', 'Заказ отправлен клиенту', '2025-11-01 10:00:00'),
(4, 'Доставлен', 'Заказ доставлен', '2025-11-01 10:00:00'),
(5, 'Отменен', 'Заказ отменен', '2025-11-01 10:00:00')
ON CONFLICT (status_id) DO NOTHING;

SELECT setval('order_statuses_status_id_seq', COALESCE((SELECT MAX(status_id) FROM order_statuses), 1), true);

INSERT INTO customers (customer_id, name, email, phone, address, created_at) VALUES
(1, 'Александр Волков', 'alex.volkov@mail.ru', '+7-495-123-45-67', 'Москва, ул. Ленина, д. 10', '2025-11-10 14:30:00'),
(2, 'Ольга Соколова', 'olga.sokolova@gmail.com', '+7-812-234-56-78', 'СПб, Невский пр., д. 25', '2025-11-12 09:15:00'),
(3, 'Сергей Новиков', 'sergey.novikov@yandex.ru', '+7-999-345-67-89', 'Казань, ул. Баумана, д. 5', '2025-11-15 16:20:00'),
(4, 'Екатерина Морозова', 'kate.morozova@mail.ru', '+7-495-456-78-90', 'Москва, ул. Тверская, д. 15', '2025-11-18 11:45:00'),
(5, 'Дмитрий Лебедев', 'dmitry.lebedeva@mail.ru', '+7-926-567-89-01', 'Москва, ул. Арбат, д. 20', '2025-11-20 13:00:00')
ON CONFLICT (customer_id) DO NOTHING;

SELECT setval('customers_customer_id_seq', COALESCE((SELECT MAX(customer_id) FROM customers), 1), true);

INSERT INTO products (product_id, product_name, category, price, created_at) VALUES
(1, 'Ноутбук ASUS ROG', 'Электроника', 95000.00, '2025-11-05 10:00:00'),
(2, 'Смартфон Samsung S24', 'Электроника', 85000.00, '2025-11-07 08:30:00'),
(3, 'Наушники Sony WH-1000XM5', 'Электроника', 25000.00, '2025-11-08 14:15:00'),
(4, 'Офисный стол', 'Мебель', 12000.00, '2025-11-03 16:45:00'),
(5, 'Эргономичное кресло', 'Мебель', 18000.00, '2025-11-06 12:20:00'),
(6, 'Монитор LG UltraWide 34"', 'Электроника', 45000.00, '2025-11-10 09:50:00'),
(7, 'Клавиатура Logitech MX Keys', 'Электроника', 8500.00, '2025-11-12 15:30:00')
ON CONFLICT (product_id) DO NOTHING;

SELECT setval('products_product_id_seq', COALESCE((SELECT MAX(product_id) FROM products), 1), true);

INSERT INTO orders (order_id, customer_id, status_id, order_date, total_amount, created_at) VALUES
(1, 1, 1, '2025-12-05', 120000.00, '2025-12-05 10:15:00'),
(2, 2, 2, '2025-12-07', 85000.00, '2025-12-07 14:30:00'),
(3, 3, 3, '2025-12-09', 45000.00, '2025-12-09 09:20:00'),
(4, 1, 4, '2025-12-10', 25000.00, '2025-12-10 16:45:00'),
(5, 4, 2, '2025-12-11', 30000.00, '2025-12-11 11:00:00'),
(6, 2, 3, '2025-12-12', 8500.00, '2025-12-12 13:25:00'),
(7, 5, 1, '2025-12-13', 18000.00, '2025-12-13 15:10:00'),
(8, 3, 4, '2025-12-14', 95000.00, '2025-12-14 10:30:00'),
(9, 1, 3, '2025-12-15', 12000.00, '2025-12-15 12:00:00'),
(10, 4, 4, '2025-12-16', 18000.00, '2025-12-16 14:20:00')
ON CONFLICT (order_id) DO NOTHING;

SELECT setval('orders_order_id_seq', COALESCE((SELECT MAX(order_id) FROM orders), 1), true);

INSERT INTO order_items (order_item_id, order_id, product_id, quantity, price, created_at) VALUES
(1, 1, 1, 1, 95000.00, '2025-12-05 10:15:00'),
(2, 1, 3, 1, 25000.00, '2025-12-05 10:15:00'),
(3, 2, 2, 1, 85000.00, '2025-12-07 14:30:00'),
(4, 3, 6, 1, 45000.00, '2025-12-09 09:20:00'),
(5, 4, 3, 1, 25000.00, '2025-12-10 16:45:00'),
(6, 5, 5, 1, 18000.00, '2025-12-11 11:00:00'),
(7, 5, 4, 1, 12000.00, '2025-12-11 11:00:00'),
(8, 6, 7, 1, 8500.00, '2025-12-12 13:25:00'),
(9, 7, 5, 1, 18000.00, '2025-12-13 15:10:00'),
(10, 8, 1, 1, 95000.00, '2025-12-14 10:30:00'),
(11, 9, 4, 1, 12000.00, '2025-12-15 12:00:00'),
(12, 10, 5, 1, 18000.00, '2025-12-16 14:20:00')
ON CONFLICT (order_item_id) DO NOTHING;

SELECT setval('order_items_order_item_id_seq', COALESCE((SELECT MAX(order_item_id) FROM order_items), 1), true);

