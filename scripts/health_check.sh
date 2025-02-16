#!/bin/bash

# Функція для перевірки HTTP сервісу
check_http_service() {
    local service_name=$1
    local url=$2
    local expected_status=$3

    echo "Перевірка $service_name..."
    status_code=$(curl -s -o /dev/null -w "%{http_code}" $url)
    
    if [ "$status_code" = "$expected_status" ]; then
        echo "✅ $service_name працює (статус: $status_code)"
        return 0
    else
        echo "❌ $service_name не працює (статус: $status_code)"
        return 1
    fi
}

# Перевірка OpenSearch
check_http_service "OpenSearch" "http://localhost:9200/_cluster/health" "200"

# Перевірка Logstash
check_http_service "Logstash" "http://localhost:9600" "200"

# Перевірка Redis
echo "Перевірка Redis..."
if docker exec redis redis-cli ping | grep -q "PONG"; then
    echo "✅ Redis працює"
else
    echo "❌ Redis не працює"
    exit 1
fi

# Перевірка LangChain API
check_http_service "LangChain API" "http://localhost:5000/health" "200"

echo "Перевірка завершена"