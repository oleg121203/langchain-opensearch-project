#!/bin/bash

# Функція для перевірки існування контейнера
check_container() {
    if ! docker ps -q -f name=$1 | grep -q .; then
        echo "Контейнер $1 не існує"
        return 1
    fi
    return 0
}

# Виправлення прав доступу для opensearch-node1
if check_container opensearch-node1; then
    docker-compose exec -T opensearch-node1 bash -c '
        mkdir -p /usr/share/opensearch/config/opensearch-security
        mkdir -p /usr/share/opensearch/config/templates
        
        # Встановлення прав доступу для директорій
        chmod -R 700 /usr/share/opensearch/config
        chmod 700 /usr/share/opensearch/config/certs
        
        # Встановлення прав доступу для файлів
        find /usr/share/opensearch/config -type f -exec chmod 600 {} \;
        
        # Встановлення власника
        chown -R 1000:1000 /usr/share/opensearch/config || true
    '
fi

# Виправлення прав доступу для opensearch-node2
if check_container opensearch-node2; then
    docker-compose exec -T opensearch-node2 bash -c '
        mkdir -p /usr/share/opensearch/config/opensearch-security
        mkdir -p /usr/share/opensearch/config/templates
        
        # Встановлення прав доступу для директорій
        chmod -R 700 /usr/share/opensearch/config
        chmod 700 /usr/share/opensearch/config/certs
        
        # Встановлення прав доступу для файлів
        find /usr/share/opensearch/config -type f -exec chmod 600 {} \;
        
        # Встановлення власника
        chown -R 1000:1000 /usr/share/opensearch/config || true
    '
fi
