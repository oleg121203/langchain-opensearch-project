#!/bin/bash

# Check if running in container
if [ -f /.dockerenv ]; then
    # Container-specific operations
    mkdir -p /usr/share/opensearch/config/certs
    chmod 750 /usr/share/opensearch/config/certs
    chmod 600 /usr/share/opensearch/config/certs/node-key.pem
    chmod 644 /usr/share/opensearch/config/certs/node.pem
    chown -R opensearch:opensearch /usr/share/opensearch/config/certs
else
    # Host-specific operations
    sudo mkdir -p ./config/certs
    sudo mkdir -p ./config/opensearch-security

    chmod 750 ./config/certs
    chmod 750 ./config/opensearch-security

    touch ./config/certs/node.pem
    touch ./config/certs/node-key.pem

    sudo chmod 644 ./config/certs/node.pem
    sudo chmod 600 ./config/certs/node-key.pem

    sudo chown -R 1000:1000 ./config/certs
    sudo chown -R 1000:1000 ./config/opensearch-security

    if command -v find &> /dev/null; then
        find ./config/opensearch-security -type f -name "*.yml" -exec chmod 644 {} \;
    fi
fi
