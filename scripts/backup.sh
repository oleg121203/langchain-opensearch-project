#!/bin/bash

# Налаштування
BACKUP_DIR="/backup"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

# Створення директорії для бекапу
mkdir -p "$BACKUP_DIR"

# Бекап Redis
echo "Створення бекапу Redis..."
docker exec redis redis-cli save
docker cp redis:/data/dump.rdb "$BACKUP_DIR/redis_$DATE.rdb"

# Бекап OpenSearch
echo "Створення бекапу OpenSearch..."
curl -X PUT "localhost:9200/_snapshot/backup_repository" -H 'Content-Type: application/json' -d'
{
  "type": "fs",
  "settings": {
    "location": "/backup"
  }
}'

curl -X PUT "localhost:9200/_snapshot/backup_repository/snapshot_$DATE?wait_for_completion=true"

# Архівування
tar -czf "$BACKUP_DIR/backup_$DATE.tar.gz" "$BACKUP_DIR/redis_$DATE.rdb" "$BACKUP_DIR/snapshot_$DATE"

# Очищення старих бекапів
find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "Бекап завершено: backup_$DATE.tar.gz"