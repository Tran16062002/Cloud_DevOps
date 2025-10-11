# Используем большой базовый образ
FROM ubuntu:latest

# Устанавливаем пакеты и обновляем систему в одной строке без очистки кеша
RUN apt-get update && apt-get install -y python3 python3-pip vim curl

# Копируем всё содержимое директории, включая ненужные файлы
COPY . /app

# Устанавливаем зависимости напрямую от root
RUN pip3 install -r /app/requirements.txt

# Запускаем контейнер от root
WORKDIR /app
CMD ["python3", "app.py"]
