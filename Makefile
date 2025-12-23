.PHONY: help up down restart logs shell psql verify test clean populate examples

help:
	@echo "Доступные команды:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

up: ## Запустить контейнер
	docker-compose up -d
	@echo "Ожидание готовности PostgreSQL..."
	@sleep 5
	@docker-compose ps

down: ## Остановить контейнер
	docker-compose down

restart: ## Перезапустить
	docker-compose restart

logs: ## Логи
	docker-compose logs -f postgres

shell: ## Bash в контейнере
	docker exec -it data-vault-orders-postgres bash

psql: ## Подключиться к БД
	docker exec -it data-vault-orders-postgres psql -U postgres -d orders_dw

verify: ## Проверить данные
	docker exec -i data-vault-orders-postgres psql -U postgres -d orders_dw < scripts/verify_data.sql

test: ## Тест партиций
	docker exec -i data-vault-orders-postgres psql -U postgres -d orders_dw < scripts/test_partitions.sql

populate: ## Заполнить Data Vault
	docker exec -i data-vault-orders-postgres psql -U postgres -d orders_dw < scripts/populate_data_vault.sql

examples: ## Примеры запросов
	docker exec -i data-vault-orders-postgres psql -U postgres -d orders_dw < scripts/query_examples.sql

clean: ## Удалить все данные
	docker-compose down -v
	@echo "Все данные удалены"

