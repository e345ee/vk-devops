# Имя Docker-образа и сервиса
IMAGE_NAME=cat-monitor-app
SERVICE_NAME=cat-app

# Сборка Docker-образа
build:
	docker build -t $(IMAGE_NAME) .

# Запуск через docker-compose
run:
	docker compose up -d

# Остановка контейнера
stop:
	docker compose down

# Быстрое обновление без пересборки образа
restart: stop run

# Полная пересборка без кэша + запуск
rebuild:
	docker compose down
	docker compose build --no-cache
	docker compose up -d

# Логи приложения и мониторинга
logs:
	docker logs -f $(SERVICE_NAME)

# Тест health-check
test:
	@echo "Running container and testing health check..."
	docker compose up -d
	sleep 4
	curl -f http://localhost:8080/health && echo " OK" || (echo " Healthcheck FAILED" && exit 1)

# Полная очистка
clean:
	docker compose down
	docker rmi -f $(IMAGE_NAME) || true

# Статус контейнера
status:
	docker ps | grep $(SERVICE_NAME) || echo "Container not running"

.PHONY: build run stop restart rebuild logs test clean status
