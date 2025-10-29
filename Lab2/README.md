# Лабораторная работа №2
Чан Тхи Лиен К3240
# Ход работы
## 1. Плохой Dockerfile (bad.Dockerfile)
```bash
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
```
## 2. Хороший Dockerfile (good.Dockerfile)
```bash
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
```
## 3. Файл app.py
```bash
from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return "Hello from Docker container!"

if __name__ == '__main__':
    # Для демонстрации запускаем на всех интерфейсах
    app.run(host='0.0.0.0', port=5000)
```
## 4. Файл requirements.txt
```bash
flask==2.3.3
```
## 5. Плохие практики в bad.Dockerfile
| № | Плохая практика | Почему плохо | Как исправлено | Результат |
|---|------------------|---------------|----------------|--------|
| 1 | Использование `ubuntu:latest` без конкретной версии |-  `latest` нестабилен и может меняться со временем<br/> - Сборки в разное время могут использовать разные версии ОС<br/> - Невозможно гарантировать воспроизводимость сборок<br/> - Может привести к неожиданным изменениям в поведении приложения | Фиксирована версия (`FROM ubuntu:20.04`) | - Гарантированная воспроизводимость сборок<br/> - Контроль за версией базового образа<br/> - Предсказуемое поведение приложения |
| 2 | Объединение всех команд в один RUN с очисткой | - Большой слой в образе из-за кэширования промежуточных файлов<br/> - Сложность отладки и модификации<br/> - Неэффективное использование кэша Docker | Исправлено: После установки — `... rm -rf /var/lib/apt/lists/*` и `pip install --no-cache-dir`. | - Более эффективное использование кэша Docker<br/> - Уменьшение размера конечного образа<br/> - Упрощение модификации и отладки |
| 3 | Запуск от имени root пользователя | - Повышение привилегий создает угрозу безопасности<br/> - При компрометации контейнера атакующий получает root-доступ<br/> - Нарушает принцип минимальных привилегий | Объединили команды (`RUN groupadd -r myuser && useradd -r -g myuser myuser` и  `USER myuser` ) | - Улучшенная безопасность<br/> - Ограничение прав при компрометации контейнера<br/> - Соответствие best practices безопасности |
## 6. Плохие практики при работе с контейнерами
### Хранить данные внутри контейнера
**Проблема:**
Запуск контейнеров с данными, хранящимися внутри контейнерной файловой системы.

**Почему это плохо:**

- Данные теряются при удалении контейнера

- Невозможно обновить приложение без потери данных

- Затруднено резервное копирование

- Невозможно масштабировать приложение

**Пример неправильного использования:**

```bash
docker run -d --name my-database my-postgres-image
```
**Правильный подход:**

```bash
# Использование volumes
docker run -d --name my-database -v postgres-data:/var/lib/postgresql/data my-postgres-image

# Или bind mounts
docker run -d --name my-database -v /host/path:/var/lib/postgresql/data my-postgres-image
```
### Запуск множества процессов в одном контейнере
**Проблема:**
Запуск нескольких несвязанных процессов в одном контейнере (например, веб-сервер и база данных).

**Почему это плохо:**

- Усложняется мониторинг и логирование

- Проблемы с управлением жизненным циклом процессов

- Нарушение принципа единственной ответственности

- Трудности с масштабированием

- Сложность в отладке проблем

**Пример неправильного использования:**

```bash
CMD service nginx start && service mysql start && tail -f /dev/null
```
**Правильный подход:**

```bash
# Запуск каждого сервиса в отдельном контейнере
docker run -d --name web-server nginx
docker run -d --name database mysql
docker run -d --name redis redis

# Использование docker-compose для оркестрации
```
## 7. Запуск проекта
```bash
docker build -f bad.Dockerfile -t bad-app .
docker run -p 5000:5000 bad-app
```
```bash
docker build -f good.Dockerfile -t good-app .
docker run -p 5000:5000 good-app
```
# Вывод
- В этой лабораторной работе показано, как выбор базового образа, порядок инструкций и настройка окружения
влияет на размер, безопасность и удобство использования контейнера.
- В результате работы были получены практические навыки по оптимизации Dockerfile и осознание важности
соблюдения принципов минимализма, безопасности и воспроизводимости при создании контейнеров.
