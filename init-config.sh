#!/bin/bash

# Створення необхідних директорій
mkdir -p config/opensearch-security
mkdir -p config/templates
mkdir -p config/certs

# Копіювання конфігураційних файлів безпеки
SECURITY_FILES=(
    "internal_users.yml"
    "roles.yml"
    "roles_mapping.yml"
    "action_groups.yml"
    "config.yml"
    "internal_users.yml"
    "nodes_dn.yml"
    "whitelist.yml"
    "tenants.yml"
)

for file in "${SECURITY_FILES[@]}"; do
    if [ -f "config/opensearch-security/$file" ]; then
        cp "config/opensearch-security/$file" "config/opensearch-security/"
        chmod 600 "config/opensearch-security/$file"
        echo "✅ Скопійовано $file"
    else
        echo "⚠️ Файл $file не знайдено"
    fi
done

# Копіювання шаблонів
cp -r config/templates/* config/templates/ 2>/dev/null || echo "⚠️ Шаблони не знайдено"

# Встановлення правильних прав доступу
chmod -R 755 config
chmod 700 config/opensearch-security
chmod 700 config/certs
find config/opensearch-security -type f -exec chmod 600 {} \;
find config/certs -type f -exec chmod 600 {} \;
find config/templates -type f -exec chmod 644 {} \;
