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
