#!/bin/bash

# Wait for OpenSearch to start
echo "Waiting for OpenSearch to start..."
until curl -s -k -u admin:Dima1203@ https://localhost:9200/_cluster/health > /dev/null; do
    echo "Waiting for OpenSearch..."
    sleep 5
done

echo "Setting up permissions..."
chmod 600 config/certs/node-key.pem
chmod 644 config/certs/node.pem

echo "Initializing security configuration..."

# Initialize security for both nodes
for node in opensearch-node1 opensearch-node2; do
    docker-compose exec $node bash -c '
        /usr/share/opensearch/plugins/opensearch-security/tools/securityadmin.sh \
        -cd /usr/share/opensearch/config/opensearch-security \
        -icl -nhnv \
        -cacert /usr/share/opensearch/config/certs/node.pem \
        -cert /usr/share/opensearch/config/certs/node.pem \
        -key /usr/share/opensearch/config/certs/node-key.pem \
        -h localhost \
        -p 9200'
done

echo "Security initialization completed"
curl -k -u admin:Dima1203@ https://localhost:9200/_cluster/health
