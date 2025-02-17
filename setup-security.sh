#!/bin/bash

# Установка правильных прав
chmod 700 config/
chmod 700 config/certs/
chmod 600 config/certs/node.pem
chmod 600 config/certs/node-key.pem

curl -XPUT -k "https://localhost:9200/_security/api/actiongroups/all_access" -u admin:Dima1203@ -H 'Content-Type: application/json' -d '
{
  "allowed_actions": ["*"]
}'
