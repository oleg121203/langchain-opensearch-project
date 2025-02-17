#!/bin/bash

# Функция для проверки существования контейнера
check_container() {
    if ! docker ps -a | grep -q $1; then
        echo "Контейнер $1 не существует"
        return 1
    fi
    return 0
}

# Fix permissions for opensearch-node1
if check_container opensearch-node1; then
    docker-compose exec -T opensearch-node1 bash -c '
        chmod 700 /usr/share/opensearch/config
        chmod 700 /usr/share/opensearch/config/certs
        chmod 600 /usr/share/opensearch/config/certs/node.pem
        chmod 600 /usr/share/opensearch/config/certs/node-key.pem
        chmod 600 /usr/share/opensearch/config/opensearch.yml
        chmod 600 /usr/share/opensearch/config/internal_users.yml
        chmod 600 /usr/share/opensearch/config/sqlformat.json
        chown -R 1000:1000 /usr/share/opensearch/config
    '
fi

# Fix permissions for opensearch-node2
if check_container opensearch-node2; then
    docker-compose exec -T opensearch-node2 bash -c '
        chmod 700 /usr/share/opensearch/config
        chmod 700 /usr/share/opensearch/config/certs
        chmod 600 /usr/share/opensearch/config/certs/node.pem
        chmod 600 /usr/share/opensearch/config/certs/node-key.pem
        chmod 600 /usr/share/opensearch/config/opensearch.yml
        chmod 600 /usr/share/opensearch/config/internal_users.yml
        chown -R 1000:1000 /usr/share/opensearch/config
    '
fi
