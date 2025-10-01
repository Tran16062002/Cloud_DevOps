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
