#!/bin/bash

CERTS_DIR="./config/certs"

# Create certs directory if it doesn't exist
mkdir -p $CERTS_DIR

# Generate CA certificate
openssl req -x509 -new -newkey rsa:4096 -keyout $CERTS_DIR/node-key.pem -out $CERTS_DIR/node.pem -days 365 -nodes -subj "/CN=node.example.com/OU=SSL/O=Test/L=Test/C=DE"

# Set correct permissions
chmod 600 $CERTS_DIR/node-key.pem
chmod 644 $CERTS_DIR/node.pem
