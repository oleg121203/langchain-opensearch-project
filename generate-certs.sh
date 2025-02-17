#!/bin/bash

CERTS_DIR="./config/certs"

# Создаем директорию для сертификатов
mkdir -p $CERTS_DIR

# Генерация самоподписанного сертификата
openssl req -x509 -newkey rsa:4096 \
    -keyout $CERTS_DIR/node-key.pem \
    -out $CERTS_DIR/node.pem \
    -days 365 \
    -nodes \
    -subj "/CN=node.example.com/OU=SSL/O=Test/L=Test/C=DE"

# Установка правильных прав
chmod 644 $CERTS_DIR/node.pem
chmod 600 $CERTS_DIR/node-key.pem
