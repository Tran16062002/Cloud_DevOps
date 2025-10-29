Чан Тхи Лиен, [29/10/2025 6:55 CH]
FROM ubuntu:latest

USER root

WORKDIR /app

COPY . .

RUN apt-get update && \
    apt-get install -y python3 python3-pip && \
    pip3 install flask && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN pip3 install -r requirements.txt

ENV APP_ENV=production
ENV DATABASE_URL=sqlite:///app.db
ENV SECRET_KEY=my-super-secret-key-12345

EXPOSE 8080

CMD python3 app.py

Чан Тхи Лиен, [29/10/2025 7:03 CH]
# Используем конкретную версию вместо latest
FROM ubuntu:20.04

# Устанавливаем переменные окружения для неинтерактивной установки
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /app

# Копируем только requirements.txt сначала для лучшего кэширования
COPY requirements.txt .

# Устанавливаем зависимости с очисткой в одном слое
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    curl && \
    pip3 install --no-cache-dir -r requirements.txt && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Создаем не-root пользователя
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Копируем исходный код
COPY app.py .

# Меняем владельца файлов
RUN chown -R appuser:appuser /app

# Переключаемся на не-root пользователя
USER appuser

# Устанавливаем переменные окружения
ENV APP_ENV=production
ENV PYTHONUNBUFFERED=1

# Используем не-privileged порт
EXPOSE 8080

# Используем exec форму для корректной обработки сигналов
CMD ["python3", "app.py"]
