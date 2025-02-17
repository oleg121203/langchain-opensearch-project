#!/bin/bash

# Create required directories
mkdir -p ./config/certs
mkdir -p ./config/opensearch-security

# Set directory permissions
chmod 750 ./config/certs
chmod 750 ./config/opensearch-security

# Generate dummy files if they don't exist (will be overwritten later)
touch ./config/certs/node.pem
touch ./config/certs/node-key.pem

# Set permissions for certificates
chmod 644 ./config/certs/node.pem
chmod 600 ./config/certs/node-key.pem

# Set ownership
chown -R 1000:1000 ./config/certs
chown -R 1000:1000 ./config/opensearch-security

# Set security config permissions
find ./config/opensearch-security -type f -name "*.yml" -exec chmod 644 {} \;

# Функція для перевірки існування контейнера
check_container() {
    if ! docker ps -q -f name=$1 | grep -q .; then
        echo "Контейнер $1 не існує"
        return 1
    fi
    return 0
}

# Fix permissions inside containers
for node in opensearch-node1 opensearch-node2; do
    docker-compose exec -T $node bash -c '
        mkdir -p /usr/share/opensearch/config/certs
        chmod 750 /usr/share/opensearch/config/certs
        chown -R 1000:1000 /usr/share/opensearch/config/certs
        chmod 600 /usr/share/opensearch/config/certs/node-key.pem
        chmod 644 /usr/share/opensearch/config/certs/node.pem
    '
done
