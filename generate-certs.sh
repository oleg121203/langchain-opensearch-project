#!/bin/bash

CERTS_DIR="config/certs"
mkdir -p $CERTS_DIR

# Проверка наличия старых сертификатов
if [ -f "$CERTS_DIR/node.pem" ]; then
    echo "Найдены существующие сертификаты. Создаем резервную копию..."
    backup_dir="$CERTS_DIR/backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    mv "$CERTS_DIR"/*.pem "$backup_dir"/ 2>/dev/null || true
fi

# Генерация сертификатов
openssl req -x509 \
    -newkey rsa:4096 \
    -keyout "$CERTS_DIR/node-key.pem" \
    -out "$CERTS_DIR/node.pem" \
    -days 365 \
    -nodes \
    -subj "/C=DE/L=Test/O=Test/OU=SSL/CN=node.example.com"

# Установка прав доступа
chmod 600 "$CERTS_DIR/node-key.pem"
chmod 644 "$CERTS_DIR/node.pem"

# Проверка сертификатов
if openssl x509 -in "$CERTS_DIR/node.pem" -text -noout > /dev/null; then
    echo "✅ Сертификаты успешно созданы в $CERTS_DIR"
else
    echo "❌ Ошибка при создании сертификатов"
    exit 1
fi
