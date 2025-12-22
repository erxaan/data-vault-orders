# Data Vault для заказов с партиционированием

Реализация схемы Data Vault для системы управления заказами с партиционированной таблицей заказов в PostgreSQL.

### Исходные таблицы

- **customers**: customer_id, name, email, phone, address
- **products**: product_id, product_name, category, price
- **order_statuses**: status_id, status_name, description
- **orders**: order_id, customer_id, status_id, order_date, total_amount
- **order_items**: order_item_id, order_id, product_id, quantity, price

### Data Vault схема

**Hubs (Хабы):**
- hub_customer - уникальные идентификаторы клиентов
- hub_product - уникальные идентификаторы продуктов
- hub_order - уникальные идентификаторы заказов
- hub_order_status - уникальные идентификаторы статусов

**Satellites (Сателлиты):**
- sat_customer - атрибуты клиентов (name, email, phone, address)
- sat_product - атрибуты продуктов (product_name, category, price)
- sat_order - атрибуты заказов (order_date, total_amount)
- sat_order_status - атрибуты статусов (status_name, description)

**Links (Линки):**
- link_order_customer - связь заказов с клиентами
- link_order_status - связь заказов со статусами
- link_order_product - связь заказов с продуктами (с quantity и price)

### Партиционированная таблица

**orders_partitioned** - партиционирована по дате заказа (RANGE), соответствует схеме Data Vault:
- Использует `order_hub_key` вместо `order_id` (соответствие Data Vault)
- Связи с другими сущностями через `customer_hub_key` и `status_hub_key`
- Данные заполняются через линки и сателлиты Data Vault
- Партиции по годам:
  - orders_2023 (2023-01-01 до 2024-01-01)
  - orders_2024 (2024-01-01 до 2025-01-01)
  - orders_2025 (2025-01-01 до 2026-01-01)
  - orders_2026 (2026-01-01 до 2027-01-01)

## Быстрый старт

```bash
# Запуск
make up

# Подключение к БД
make psql

# Проверка данных
make verify

# Тест партиций
make test
```

## Использование

Скрипты из `init-scripts/` выполняются автоматически при первом запуске

Для ручного запуска используйте скрипты из `scripts/`:

```bash
make populate      # заполнить Data Vault
make partitioned   # заполнить партиции
make test         # тест партиций
make verify       # проверка целостности
make examples     # примеры запросов
```

## Примеры

```sql
-- Запрос из партиционированной таблицы
SELECT * FROM orders_partitioned
WHERE order_date >= '2025-12-01'
ORDER BY order_date DESC;

-- Заказы с клиентами через Data Vault (из партиционированной таблицы)
SELECT sc.name, op.order_date, op.total_amount, sos.status_name
FROM orders_partitioned op
JOIN sat_customer sc ON op.customer_hub_key = sc.customer_hub_key
JOIN sat_order_status sos ON op.status_hub_key = sos.status_hub_key
WHERE sc.load_end_date IS NULL AND sos.load_end_date IS NULL
ORDER BY op.order_date DESC;
```

## Остановка

```bash
make down      # остановить
make clean     # остановить и удалить данные
```

**Параметры БД**: PostgreSQL 15, порт 5433, БД: orders_dw, пользователь/пароль: postgres

