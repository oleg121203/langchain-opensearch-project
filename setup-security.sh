#!/bin/bash

# Set permissions
chmod 700 config/
chmod 700 config/certs/
chmod 600 config/certs/node.pem
chmod 600 config/certs/node-key.pem

# Create admin user
curl -XPUT -k "https://localhost:9200/_security/user/admin" -u admin:Dima1203@ -H 'Content-Type: application/json' -d '
{
  "password": "Dima1203@",
  "roles": ["admin"],
  "full_name": "Admin"
}'

# Configure admin role
curl -XPUT -k "https://localhost:9200/_security/role/admin" -u admin:Dima1203@ -H 'Content-Type: application/json' -d '
{
  "cluster_permissions": ["*"],
  "index_permissions": [{
    "index_patterns": ["*"],
    "allowed_actions": ["*"]
  }]
}'
