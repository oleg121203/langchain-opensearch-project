#!/bin/bash

# Wait for OpenSearch to start
echo "Waiting for OpenSearch to start..."
until curl -s -k https://localhost:9200 -u admin:Dima1203@ > /dev/null; do
    sleep 5
done

# Initialize security
docker-compose exec opensearch-node1 bash -c '
    chmod +x plugins/opensearch-security/tools/securityadmin.sh && \
    plugins/opensearch-security/tools/securityadmin.sh \
        -cd plugins/opensearch-security/securityconfig/ \
        -icl -nhnv \
        -cacert config/certs/node.pem \
        -cert config/certs/node.pem \
        -key config/certs/node-key.pem \
        -h localhost \
        -p 9200'

# Create admin user
curl -X PUT "https://localhost:9200/_security/api/internalusers/admin" \
     -H "Content-Type: application/json" \
     -k -u admin:Dima1203@ \
     -d '{
       "password": "Dima1203@",
       "opendistro_security_roles": ["admin"],
       "backend_roles": ["admin"],
       "attributes": {}
     }'
