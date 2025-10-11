# Используем лёгкий базовый образ
FROM python:3.10-slim

# Создаём отдельного пользователя для безопасности
RUN useradd -m appuser

# Устанавливаем зависимости только из requirements.txt и очищаем кеш apt
WORKDIR /app
COPY requirements.txt .
RUN apt-get update && apt-get install -y --no-install-recommends \
    && pip install --no-cache-dir -r requirements.txt \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Копируем только нужные файлы приложения
COPY app.py .

# Переключаемся на непривилегированного пользователя
USER appuser

# Запускаем Flask-приложение
CMD ["python", "app.py"]
