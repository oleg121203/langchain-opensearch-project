#!/bin/bash

# Функція для логування
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Перевірка статусу виконання
check_status() {
    if [ $? -eq 0 ]; then
        log "✅ $1"
    else
        log "❌ $1"
        exit 1
    fi
}

# Перелік всіх сервісів
ALL_SERVICES="opensearch-node1 opensearch-node2 opensearch-dashboards redis logstash langchain"

# Функція для показу допомоги
show_help() {
    echo "Використання: $0 [ОПЦІЇ] [КОМАНДА]"
    echo
    echo "Команди:"
    echo "  start         Запустити сервіси"
    echo "  stop          Зупинити сервіси"
    echo "  restart       Перезапустити сервіси"
    echo "  status       Показати статус сервісів"
    echo "  logs         Показати логи"
    echo "  rebuild      Перезібрати сервіси"
    echo "  clean        Повне очищення та перезапуск всіх сервісів"
    echo
    echo "Опції:"
    echo "  --all        Застосувати до всіх сервісів"
    echo "  --services   Вказати конкретні сервіси (через пробіл)"
    echo
    echo "Приклади:"
    echo "  $0 start --all"
    echo "  $0 restart --services 'opensearch langchain'"
    echo "  $0 logs --services redis"
    echo "  $0 rebuild --all"
}

# Парсинг аргументів
COMMAND=""
REBUILD_ALL=false
SERVICES=""

while [[ $# -gt 0 ]]; do
    case $1 in
        start|stop|restart|status|logs|rebuild|clean)
            COMMAND=$1
            shift
            ;;
        --all)
            SERVICES=$ALL_SERVICES
            shift
            ;;
        --services)
            SERVICES=$2
            shift 2
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            log "❌ Невідомий параметр: $1"
            show_help
            exit 1
            ;;
    esac
done

# Якщо сервіси не вказані, використовуємо всі
if [ -z "$SERVICES" ]; then
    SERVICES=$ALL_SERVICES
fi

# Добавим функцию для работы с сертификатами
setup_certificates() {
    log "🔒 Настройка сертификатов..."
    if [ ! -f "generate-certs.sh" ]; then
        log "❌ Файл generate-certs.sh не найден"
        return 1
    fi
    
    chmod +x generate-certs.sh
    ./generate-certs.sh
    check_status "Генерация сертификатов"
}

# Добавляем функцию настройки прав доступа
setup_permissions() {
    log "🔐 Настройка прав доступа..."
    
    for node in "opensearch-node1" "opensearch-node2"; do
        docker-compose exec -T $node bash -c '
            chmod 700 /usr/share/opensearch/config
            chmod 700 /usr/share/opensearch/config/certs
            chmod 600 /usr/share/opensearch/config/certs/node.pem
            chmod 600 /usr/share/opensearch/config/opensearch.yml
            chown -R 1000:1000 /usr/share/opensearch/config/certs
        ' || log "⚠️ Ошибка настройки прав для $node"
    done
    
    check_status "Налаштування прав доступу"
}

# Функция установки прав на скрипты
setup_scripts_permissions() {
    log "🔧 Установка прав доступа на скрипты..."
    
    # Список всех скриптов
    SCRIPTS=(
        "restart.sh"
        "setup.sh"
        "setup-security.sh"
        "generate-certs.sh"
        "init-security.sh"
        "fix-permissions.sh"
        "scripts/backup.sh"
        "scripts/health_check.sh"
        "scripts/setup.sh"
    )
    
    for script in "${SCRIPTS[@]}"; do
        if [ -f "$script" ]; then  # Исправлено с -ф на -f
            chmod +x "$script"
            log "✅ Установлены права на $script"
        else
            log "⚠️ Скрипт $script не найден"
        fi
    done
    
    check_status "Установка прав на скрипты"
}

# Добавляем новую функцию для настройки прав сертификатов
setup_certs_permissions() {
    log "🔑 Настройка прав доступа к сертификатам..."
    
    if [ -d "config/certs" ]; then  # Исправлено с -д на -d
        log "Удаление существующей директории сертификатов..."
        sudo rm -rf config/certs
    fi
    
    mkdir -p config/certs
    chmod 755 config/certs
    check_status "Настройка прав доступа к сертификатам"
}

# Исправляем функцию проверки кластера
check_cluster_health() {
    log "🔍 Проверка здоровья кластера..."
    for i in {1..60}; do
        local health=$(curl -s -k -u admin:Dima1203@ https://localhost:9200/_cluster/health)
        if [[ $health == *'"status":"green"'* ]] || [[ $health == *'"status":"yellow"'* ]]; then
            log "✅ Кластер OpenSearch работает нормально"
            return 0
        fi
        log "⏳ Ожидание готовности кластера... ($i/60)"
        sleep 10
    done  # Исправлено 'end' на 'done'
    log "❌ Кластер OpenSearch не готов"
    return 1
}

# Добавляем функцию проверки сети
check_network() {
    log "🌐 Перевірка мережі..."
    if docker network inspect langchain-network >/dev/null 2>&1; then
        log "Видалення існуючої мережі..."
        docker network rm langchain-network 2>/dev/null || true
    fi
    check_status "Перевірка мережі"
}

# Добавляем функцию проверки логов OpenSearch
check_opensearch_logs() {
    log "📋 Проверка логов OpenSearch..."
    log "=== Логи opensearch-node1 ==="
    docker-compose logs opensearch-node1 | tail -n 50
    log "=== Логи opensearch-node2 ==="
    docker-compose logs opensearch-node2 | tail -n 50
}

# Добавляем функцию для запуска init-security.sh
run_init_security() {
    log "🔐 Инициализация безопасности OpenSearch..."
    if [ -f "init-security.sh" ]; then
        chmod +x init-security.sh
        ./init-security.sh
        check_status "Инициализация безопасности"
    else
        log "⚠️ Файл init-security.sh не найден"
    fi
}

# Добавляем функцию для запуска fix-permissions.sh
run_fix_permissions() {
    log "📝 Исправление прав доступа..."
    if [ -f "fix-permissions.sh" ]; then
        chmod +x fix-permissions.sh
        ./fix-permissions.sh
        check_status "Исправление прав доступа"
    else
        log "⚠️ Файл fix-permissions.sh не найден"
    fi
}

case $COMMAND in
    start)
        log "Запуск сервісів: $SERVICES"
        setup_scripts_permissions
        docker-compose up -d $SERVICES
        check_status "Запуск сервісів"
        setup_permissions
        check_cluster_health
        ;;
    stop)
        log "Зупинка сервісів: $SERVICES"
        docker-compose stop $SERVICES
        check_status "Зупинка сервісів"
        ;;
    restart)
        log "Перезапуск сервісів: $SERVICES"
        docker-compose restart $SERVICES
        check_status "Перезапуск сервісів"
        ;;
    status)
        log "Статус сервісів: $SERVICES"
        docker-compose ps $SERVICES
        ;;
    logs)
        log "Показ логів для: $SERVICES"
        docker-compose logs --tail=100 -f $SERVICES
        ;;
    rebuild)
        log "Перезбірка сервісів: $SERVICES"
        setup_scripts_permissions
        docker-compose down
        setup_certificates
        run_fix_permissions
        run_init_security
        docker-compose build --no-cache $SERVICES
        docker-compose up -d $SERVICES
        setup_permissions
        check_status "Перезбірка сервісів"
        ;;
    clean)
        log "🧹 Повне очищення та перезапуск системи..."
        
        # Останавливаем все контейнеры
        docker-compose down --remove-orphans
        sleep 5
        
        # Очищаем volumes
        docker volume rm $(docker volume ls -q | grep 'langchain-opensearch-project') 2>/dev/null || true
        
        # Настройка окружения
        setup_scripts_permissions
        setup_certs_permissions
        setup_certificates
        
        # Запускаем контейнеры
        log "🚀 Запуск системи..."
        docker-compose up -d
        sleep 30  # Увеличиваем время ожидания
        
        # Теперь можно исправлять права
        run_fix_permissions
        run_init_security
        
        if ! check_cluster_health; then
            check_opensearch_logs
            log "🔄 Пробуем перезапустить ноды..."
            docker-compose restart opensearch-node1 opensearch-node2
            sleep 30
            check_cluster_health
        fi
        
        log "📊 Статус системи:"
        docker-compose ps
        ;;
    *)
        log "❌ Не вказана команда"
        show_help
        exit 1
        ;;
esac

# Перевірка статусу
if [ "$COMMAND" != "logs" ]; then
    log "Перевірка статусу сервісів..."
    for service in $SERVICES; do
        if docker-compose ps --format "{{.State}}" $service | grep -q "running\|healthy"; then
            log "✅ $service працює"
            
            # Дополнительная проверка для нод OpenSearch
            if [[ $service == opensearch-node* ]]; then
                local node_health=$(curl -s -k -u admin:Dima1203@ https://localhost:9200/_nodes/$service/stats)
                if [[ $node_health == *'"status":"green"'* ]] || [[ $node_health == *'"status":"yellow"'* ]]; then
                    log "  └─ Нода в кластере активна"
                else
                    log "  └─ ⚠️ Проблемы с нодой в кластере"
                fi
            fi
        else
            log "❌ $service не запущено"
        fi
    done
fi
