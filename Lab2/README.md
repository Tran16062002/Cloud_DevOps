# Лабораторная работа №2
Чан Тхи Лиен К3240
# Ход работы
## 1. Плохой Dockerfile (bad.Dockerfile)
```bash
# Используем большой базовый образ
FROM ubuntu:latest

# Устанавливаем пакеты и обновляем систему в одной строке без очистки кеша
RUN apt-get update
RUN apt-get install -y python3 python3-pip
RUN pip3 install flask

# Копируем всё содержимое директории, включая ненужные файлы
COPY . /app

# Устанавливаем зависимости напрямую от root
RUN pip3 install -r /app/requirements.txt

# Запускаем контейнер от root
WORKDIR /app

RUN useradd -m myuser
USER myuser

EXPOSE 5000

CMD ["python3", "app.py"]
```
## 2. Хороший Dockerfile (good.Dockerfile)
```bash
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
flask==3.0.3
```
## 5. Плохие практики в bad.Dockerfile
| № | Плохая практика | Почему плохо | Как исправлено | Эффект |
|---|------------------|---------------|----------------|--------|
| 1 | Использование `ubuntu:latest` без конкретной версии | `latest` меняется при каждом обновлении, непредсказуемое поведение | Фиксирована версия (`python:3.9-slim`) | Используется конкретная версия Python (3.9) и образ `slim` меньше по размеру и содержит только необходимые компоненты |
| 2 | Множественные RUN команды для установки пакетов | Каждая команда RUN создает новый слой в образе и увеличивается размер итогового образа | Исправлено: После установки — `apt-get clean && rm -rf /var/lib/apt/lists/*` и `pip install --no-cache-dir`. | Объединение команд уменьшает количество слоев и очистка кэша apt уменьшает размер образа |
| 3 | Позднее создание пользователя и копирование файлов | Файлы копируются с правами root и файлы могут иметь неправильные права доступа | Объединили команды (`RUN groupadd -r myuser && useradd -r -g myuser myuser` и `COPY --chown=myuser:myuser . /app` `USER myuser` ) | Улучшена безопасность (приложение запускается не от root) и использование флагов -r для создания системного пользователя |
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
