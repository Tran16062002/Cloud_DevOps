FROM python:3.9-slim

# Установка зависимостей системы
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Создание пользователя перед установкой зависимостей приложения
RUN groupadd -r myuser && useradd -r -g myuser myuser

# Копирование файла зависимостей и установка
COPY requirements.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Копирование исходного кода
COPY --chown=myuser:myuser . /app

WORKDIR /app

USER myuser

EXPOSE 5000

# Использование exec формы для CMD
CMD ["python", "app.py"]
