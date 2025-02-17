#!/bin/bash

# Wait for OpenSearch to start
echo "Waiting for OpenSearch to start..."
until curl -s -k https://localhost:9200 -u admin:Dima1203@ > /dev/null; do
    sleep 10
done

echo "Initializing security configuration..."

# Initialize security configuration for both nodes
for node in opensearch-node1 opensearch-node2; do
    docker-compose exec $node bash -c '
        chmod +x plugins/opensearch-security/tools/securityadmin.sh && \
        plugins/opensearch-security/tools/securityadmin.sh \
            -cd plugins/opensearch-security/securityconfig/ \
            -icl -nhnv \
            -cacert config/certs/node.pem \
            -cert config/certs/node.pem \
            -key config/certs/node-key.pem \
            -h localhost \
            -p 9200 \
            -cd /usr/share/opensearch/config/opensearch-security/ \
            -rev \
            -f
    '
done

# Check security status
curl -k -X GET "https://localhost:9200/_cluster/health" -u admin:Dima1203@
