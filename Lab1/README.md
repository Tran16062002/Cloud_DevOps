# Лабораторная работа №1

Чан Тхи Лиен К3240

# Ход работы

1. Устанавливать **nginx**.

   ```bash
   sudo apt install nginx
   ```
   
2. Структура проекта.
  ```bash
   /var/www/

├── project1/

│       ├── index.html

│       └── assets/

│                 └── style.css

└── project2/
       
        ├── index.html
       
        └── api/
               
                   └── test.php
  ```
3. Генерация SSL сертификатов.

- Создать директорию для сертификатов

   ```bash
   sudo mkdir -p /etc/nginx/ssl
   ```
- Генерируем сертификат для project1.example.com и project2.example.com

   ```bash
   sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/project1.example.com.key \
    -out /etc/nginx/ssl/project1.example.com.crt \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=Company/CN=project1.example.com"
   ```
   ```bash
   sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/project2.example.com.key \
    -out /etc/nginx/ssl/project2.example.com.crt \
    -subj "/C=RU/ST=Moscow/L=Moscow/O=Company/CN=project2.example.com"
   ```

4. Основной конфигурационный файл **nginx**.

В файле **/etc/nginx/nginx.conf** добавлять содержимое

```bash
   user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    # Базовые настройки
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # MIME типы
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # Логи
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    # Настройки SSL
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Включаем виртуальные хосты
    include /etc/nginx/sites-enabled/*;
}
   ```
5. Конфигурация для project1.

В файле /etc/nginx/sites-available/project1.example.com:

   ```bash
   # HTTP редирект на HTTPS
server {
    listen 80;
    server_name project1.example.com www.project1.example.com;
    
    # Принудительный редирект на HTTPS
    return 301 https://$server_name$request_uri;
}

# HTTPS сервер
server {
    listen 443 ssl http2;
    server_name project1.example.com www.project1.example.com;

    # SSL сертификаты
    ssl_certificate /etc/nginx/ssl/project1.example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/project1.example.com.key;

    # Безопасность
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    # Корневая директория
    root /var/www/project1;
    index index.html index.htm;

    # Основной location
    location / {
        try_files $uri $uri/ =404;
    }

    # Alias для статических файлов
    location /static/ {
        alias /var/www/project1/assets/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Alias для специального пути
    location /special-files/ {
        alias /var/www/project1/special-assets/;
        autoindex off;
    }

    # Обработка ошибок
    error_page 404 /404.html;
    error_page 500 502 503 504 /50x.html;

    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
   ```

6. Конфигурация для project2.

В файле /etc/nginx/sites-available/project1.example.com:

   ```bash
   # HTTP редирект на HTTPS
server {
    listen 80;
    server_name project2.example.com api.project2.example.com;
    
    # Принудительный редирект на HTTPS
    return 301 https://$server_name$request_uri;
}

# HTTPS сервер
server {
    listen 443 ssl http2;
    server_name project2.example.com api.project2.example.com;

    # SSL сертификаты
    ssl_certificate /etc/nginx/ssl/project2.example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/project2.example.com.key;

    # Безопасность
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;

    # Корневая директория
    root /var/www/project2;
    index index.html index.php;

    # Основной location
    location / {
        try_files $uri $uri/ =404;
    }

    # Alias для API endpoints
    location /api/ {
        alias /var/www/project2/api/;
        
        # Обработка PHP файлов
        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
            fastcgi_param SCRIPT_FILENAME $request_filename;
        }
    }

    # Обработка PHP файлов
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    # Запрет доступа к скрытым файлам
    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
   ```
7. Активация сайтов.

- Создать симлинки
   ```bash
   sudo ln -s /etc/nginx/sites-available/project1.example.com /etc/nginx/sites-enabled/
   sudo ln -s /etc/nginx/sites-available/project2.example.com /etc/nginx/sites-enabled/
   ```
- Проверять конфигурацию
   ```bash
   sudo nginx -t
   ```
- Перезапускать **nginx**
   ```bash
   sudo systemctl reload nginx
   ```
8. Создать тестовые файлы проектов.
- Project 1 (/var/www/project1/index.html):
- Project 1 CSS (/var/www/project1/assets/style.css):
- Project 2 (/var/www/project2/index.html):
- Project 2 API (/var/www/project2/api/test.php):
9. Настройка hosts файла для локального тестирования.

Добвлять в /etc/hosts:
```bash
127.0.0.1 project1.example.com www.project1.example.com
127.0.0.1 project2.example.com api.project2.example.com
```
10. Проверка работы.
- Проверяем HTTP редирект
- Проверяем HTTPS
- Проверяем alias
- Проверяем web
# Вывод
В лаборатории я знакомилась и научилась веб-сервес **nginx**, создать **SSL** сертификатов, настраивать перенаправление **HTTP→HTTPS**, 
добавлять псевдонимы для создания псевдонимов для путей к каталогам на сервере и тестировать работу сайта и перенаправление с помощью **curl**.
