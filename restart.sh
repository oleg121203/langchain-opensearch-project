#!/bin/bash

# Функция для логирования с временной меткой
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Получаем список всех сервисов
SERVICES="opensearch redis logstash langchain"

# Получаем команду из аргументов
COMMAND=${1:-"restart"}

case $COMMAND in
    "clean")
        log "Очистка и перезапуск всех сервисов..."
        docker-compose down -v
        docker-compose up -d
        ;;
    "restart")
        log "Перезапуск сервисов..."
        docker-compose restart
        ;;
    "logs")
        log "Показ логів..."
        docker-compose logs -f
        ;;
    *)
        log "Невідома команда. Використовуйте: clean, restart або logs"
        exit 1
        ;;
esac

# Проверка статуса сервисов
if [ "$COMMAND" != "logs" ]; then
    log "Перевірка статусу сервісів..."
    for service in $SERVICES; do
        if docker-compose ps --format "{{.State}}" $service | grep -q "running\|healthy"; then
            log "✅ $service працює"
        else
            log "❌ $service не запущено"
        fi
    done
fi
