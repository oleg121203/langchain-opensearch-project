#!/bin/bash

# Налаштування системних параметрів для OpenSearch
echo "Налаштування системних параметрів..."
sudo sysctl -w vm.max_map_count=262144
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf

# Створення необхідних директорій
echo "Створення директорій..."
mkdir -p csv_data logs/{langchain,logstash}

# Налаштування прав доступу
echo "Налаштування прав доступу..."
chmod +x scripts/*.sh
chmod 755 logs csv_data

# Перевірка наявності Docker
if ! command -v docker &> /dev/null; then
    echo "Docker не встановлено. Встановіть Docker перед продовженням."
    exit 1
fi

# Перевірка наявності Docker Compose
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose не встановлено. Встановіть Docker Compose перед продовженням."
    exit 1
fi

# Встановлення Python залежностей
echo "Встановлення Python залежностей..."
python -m pip install -r requirements.txt

echo "Налаштування завершено"