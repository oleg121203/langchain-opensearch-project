#!/bin/bash

# Wait for OpenSearch to start
echo "Waiting for OpenSearch to start..."
until curl -s -k https://localhost:9200 -u admin:Dima1203@ > /dev/null; do
    sleep 5
done

# Initialize security configuration
docker-compose exec opensearch-node1 bash -c '
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
        -rev
'

# Verify admin user
curl -X GET "https://localhost:9200/_security/user/admin" \
     -H "Content-Type: application/json" \
     -k -u admin:Dima1203@

# Create reader user
curl -X PUT "https://localhost:9200/_security/api/internalusers/reader" \
     -H "Content-Type: application/json" \
     -k -u admin:Dima1203@ \
     -d '{
       "password": "reader123",
       "opendistro_security_roles": ["reader"],
       "attributes": {}
     }'
