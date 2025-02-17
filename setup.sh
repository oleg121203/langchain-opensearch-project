#!/bin/bash

# Установка прав доступа
chmod 700 /usr/share/opensearch/config
chmod 600 /usr/share/opensearch/config/certs/node.pem
chmod 600 /usr/share/opensearch/config/certs/node-key.pem

# Ждем пока OpenSearch запустится
until curl -s -k -u admin:Dima1203@ https://localhost:9200/_cluster/health > /dev/null; do
    echo "Ожидание запуска OpenSearch..."
    sleep 5
done

# Применяем шаблоны
curl -X PUT "https://localhost:9200/_template/customs" \
     -k \
     -u admin:Dima1203@ \
     -H 'Content-Type: application/json' \
     -d @./config/templates/customs.json

echo "Настройка OpenSearch завершена"

# Расширенная проверка SSL
check_ssl() {
    local ssl_info=$(curl -s -k -u admin:Dima1203@ https://localhost:9200/_ssl/certificates)
    if echo "$ssl_info" | grep -q "node.example.com" && \
       echo "$ssl_info" | grep -q "DN=CN=node.example.com, OU=SSL, O=Test, L=Test, C=DE"; then
        echo "✅ SSL сертификаты настроены корректно"
        return 0
    else
        echo "❌ Проблема с SSL сертификатами"
        echo "Детали: $ssl_info"
        return 1
    fi
}

check_ssl || exit 1
