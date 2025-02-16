# Stage 1: Builder
FROM python:3.11-slim as builder

WORKDIR /build

# Встановлення системних залежностей для збірки
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Копіювання та встановлення залежностей
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim

# Встановлення системних утиліт
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Налаштування локалізації
ENV LANG=uk_UA.UTF-8 \
    LANGUAGE=uk_UA:uk \
    LC_ALL=uk_UA.UTF-8

RUN apt-get update && apt-get install -y locales && \
    sed -i -e 's/# uk_UA.UTF-8 UTF-8/uk_UA.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales

# Створення непривілейованого користувача
RUN useradd -m -u 1000 appuser

# Створення необхідних директорій
WORKDIR /app
RUN mkdir -p /app/logs /app/data /app/config && \
    chown -R appuser:appuser /app

# Копіювання Python пакетів з builder
COPY --from=builder /root/.local /home/appuser/.local
ENV PATH=/home/appuser/.local/bin:$PATH

# Копіювання коду програми
COPY --chown=appuser:appuser . .

# Налаштування змінних середовища
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH="/home/appuser/.local/bin:$PATH" \
    LOG_LEVEL=INFO

# Налаштування прав доступу
RUN chmod +x scripts/* && \
    chown -R appuser:appuser /app

# Перехід на непривілейованого користувача
USER appuser

# Відкриття порту
EXPOSE 5000

# Створення volume для логів та даних
VOLUME ["/app/logs", "/app/data"]

# Команда запуску
CMD ["python", "app.py"]