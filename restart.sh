#!/bin/bash

# Зупиняємо всі контейнери
docker-compose down -v

# Очищаємо всі томи
docker volume prune -f

# Перезапускаємо з перебудовою
docker-compose up --build -d

# Чекаємо запуску OpenSearch
echo "Очікування запуску OpenSearch..."
sleep 30

# Перевіряємо статус
docker-compose ps
