# Лабораторная работа №2 со звездочкой
Чан Тхи Лиен К3240
# Ход работы
## 1. Плохой docker-compose.yml (bad-compose.yml)
```bash
version: '3'
services:
  app:
    build:
      context: .
      dockerfile: bad.Dockerfile
    ports:
      - "5000:5000"
    # Плохая практика 1: используем latest вместо фиксированной версии
    image: flaskapp:latest

    # Плохая практика 2: запускаем под root и даём доступ к / (всей файловой системе хоста)
    volumes:
      - /:/app/host_root

    # Плохая практика 3: хардкодим пароли и переменные среды прямо в compose
    environment:
      - SECRET_KEY=mysecretpassword
      - DEBUG=True

  db:
    image: postgres:latest
    environment:
      POSTGRES_USER: root
      POSTGRES_PASSWORD: root
      POSTGRES_DB: mydb
    # Плохая практика 4: открываем порт базы наружу (хотя она используется только приложением)
    ports:
      - "5432:5432"
```
## 2. Хороший docker-compose.yml (good-compose.yml)
```bash
version: '3.9'
services:
  app:
    build:
      context: .
      dockerfile: good.Dockerfile
    image: flaskapp:1.0
    ports:
      - "5000:5000"
    env_file:
      - .env
    volumes:
      - ./app_data:/app/data
    user: "1000:1000"
    networks:
      - app_net

  db:
    image: postgres:15-alpine
    env_file:
      - .env
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - db_net

volumes:
  db_data:
  app_data:

# Каждая сеть изолирована, поэтому контейнеры не видят друг друга
networks:
  app_net:
    internal: true
  db_net:
    internal: true
```
## 3. Файл .env
```bash
SECRET_KEY=super_secret_key
DEBUG=False
POSTGRES_USER=appuser
POSTGRES_PASSWORD=securepassword123
POSTGRES_DB=mydatabase
```
## 4. Плохие практики в bad-compose.yml
| № | Плохая практика | Почему плохо | Как исправлено | Эффект |
|---|------------------|---------------|----------------|--------|
| 1 | Использование `latest` в `image:` | `latest` меняется при каждом обновлении, непредсказуемое поведение | Фиксирована версия (`flaskapp:1.0`, `postgres:15-alpine`) | Повторяемость сборки |
| 2 | Проброс всей файловой системы (`/:/app/host_root`) | Очень опасно — контейнер получает доступ ко всему хосту | Ограничен том `./app_data:/app/data` | Безопасность и изоляция |
| 3 | Секреты и пароли в `environment:` прямо в файле | Секреты могут утечь в репозиторий | Использован `.env` файл | Безопасное хранение переменных |
| 4 | Порт базы данных 5432 открыт наружу | Любой может подключиться к базе | Порт убран, контейнер изолирован внутренней сетью | Безопасность БД |
## 5. Как контейнеры поднимаются, но не "видят" друг друга
### В хорошем файле мы создали **две разные сети**:
- `app_net` — для Flask-приложения  
- `db_net` — для PostgreSQL  

### И обе сети объявлены как **internal: true**.  
Это означает, что Docker создаёт внутренние виртуальные сети, недоступные извне и **изолированные друг от друга**.
### В результате:
- Контейнеры **запускаются вместе** (оба определены в одном `docker-compose.yml`);
- Но они **не имеют маршрутов друг к другу** — ни по имени сервиса, ни по IP.
## 6. Как запустить
```bash
docker compose -f bad-compose.yml up --build
```
```bash
docker compose -f good-compose.yml up --build
```
# Вывод
- В результате работы были продемонстрированы плохие и хорошие практики при создании Docker Compose файлов.
- Исправленные ошибки позволили:

повысить безопасность (нет утечек секретов, нет root-доступа к хосту),

обеспечить повторяемость сборки (зафиксированные версии образов),

сделать архитектуру чище и изолированнее (разные внутренние сети),

упростить управление настройками через .env.

- Также была реализована изоляция контейнеров на уровне сети, что предотвращает их прямое взаимодействие при 
совместном запуске, сохраняя при этом их одновременный запуск и управление через один Compose-проект.
