# Stage 1: Builder
FROM python:3.11-slim as builder

WORKDIR /build

# Встановлення системних залежностей та локалей
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    locales \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/uk_UA.UTF-8/s/^# //g' /etc/locale.gen \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen

ENV LANG=uk_UA.UTF-8 \
    LANGUAGE=uk_UA:uk \
    LC_ALL=uk_UA.UTF-8

# Копіювання та встановлення залежностей
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim

# Встановлення системних утиліт та локалей
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    locales \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/uk_UA.UTF-8/s/^# //g' /etc/locale.gen \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen

ENV LANG=uk_UA.UTF-8 \
    LANGUAGE=uk_UA:uk \
    LC_ALL=uk_UA.UTF-8

# Створення непривілейованого користувача та директорій
RUN useradd -m -u 1000 appuser
WORKDIR /app
RUN mkdir -p /app/logs /app/data /app/config && \
    chown -R appuser:appuser /app

# Копіювання Python пакетів та коду
COPY --from=builder /root/.local /home/appuser/.local
COPY --chown=appuser:appuser . .

ENV PATH=/home/appuser/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
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