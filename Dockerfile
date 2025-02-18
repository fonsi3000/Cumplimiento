FROM php:8.2-cli

ENV TZ=America/Bogota

# Instala dependencias del sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip \
    unzip \
    libbrotli-dev \
    pkg-config \
    libicu-dev

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# Configura git para el directorio
RUN git config --global --add safe.directory /var/www/html

# Instala extensiones PHP
RUN docker-php-ext-install \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip \
    intl

# Configura intl
RUN docker-php-ext-configure intl

# Instala Swoole
RUN pecl install swoole && \
    docker-php-ext-enable swoole

# Instala Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configura el directorio de trabajo
WORKDIR /var/www/html

# Copia los archivos de la aplicación
COPY . .

# Crea el archivo .env con la configuración específica
RUN echo 'APP_NAME="Cumplimiento EM & EL"' > .env && \
    echo 'APP_ENV=local' >> .env && \
    echo 'APP_KEY=base64:fncqQOhCOM7JALFneYpduxdQjUREESC8zMrbueNemsU=' >> .env && \
    echo 'APP_DEBUG=true' >> .env && \
    echo 'APP_TIMEZONE=UTC' >> .env && \
    echo 'APP_URL=http://localhost:5000' >> .env && \
    echo 'APP_LOCALE=es' >> .env && \
    echo 'APP_FALLBACK_LOCALE=es' >> .env && \
    echo 'APP_FAKER_LOCALE=es_COL' >> .env && \
    echo 'APP_MAINTENANCE_DRIVER=file' >> .env && \
    echo 'PHP_CLI_SERVER_WORKERS=4' >> .env && \
    echo 'BCRYPT_ROUNDS=12' >> .env && \
    echo 'LOG_CHANNEL=stack' >> .env && \
    echo 'LOG_STACK=single' >> .env && \
    echo 'LOG_DEPRECATIONS_CHANNEL=null' >> .env && \
    echo 'LOG_LEVEL=debug' >> .env && \
    echo 'DB_CONNECTION=mysql' >> .env && \
    echo 'DB_HOST=db' >> .env && \
    echo 'DB_PORT=3306' >> .env && \
    echo 'DB_DATABASE=cumplimiento_em' >> .env && \
    echo 'DB_USERNAME=root' >> .env && \
    echo 'DB_PASSWORD=Espumas2025*.' >> .env && \
    echo 'SESSION_DRIVER=database' >> .env && \
    echo 'SESSION_LIFETIME=120' >> .env && \
    echo 'SESSION_ENCRYPT=false' >> .env && \
    echo 'SESSION_PATH=/' >> .env && \
    echo 'SESSION_DOMAIN=null' >> .env && \
    echo 'BROADCAST_CONNECTION=log' >> .env && \
    echo 'FILESYSTEM_DISK=local' >> .env && \
    echo 'QUEUE_CONNECTION=database' >> .env && \
    echo 'CACHE_STORE=database' >> .env && \
    echo 'CACHE_PREFIX=' >> .env && \
    echo 'MEMCACHED_HOST=db' >> .env && \
    echo 'REDIS_CLIENT=phpredis' >> .env && \
    echo 'REDIS_HOST=redis' >> .env && \
    echo 'REDIS_PASSWORD=null' >> .env && \
    echo 'REDIS_PORT=6379' >> .env && \
    echo 'MAIL_MAILER=log' >> .env && \
    echo 'MAIL_SCHEME=null' >> .env && \
    echo 'MAIL_HOST=mailhog' >> .env && \
    echo 'MAIL_PORT=1025' >> .env && \
    echo 'MAIL_USERNAME=null' >> .env && \
    echo 'MAIL_PASSWORD=null' >> .env && \
    echo 'MAIL_FROM_ADDRESS="hello@example.com"' >> .env && \
    echo 'MAIL_FROM_NAME="${APP_NAME}"' >> .env && \
    echo 'AWS_ACCESS_KEY_ID=' >> .env && \
    echo 'AWS_SECRET_ACCESS_KEY=' >> .env && \
    echo 'AWS_DEFAULT_REGION=us-east-1' >> .env && \
    echo 'AWS_BUCKET=' >> .env && \
    echo 'AWS_USE_PATH_STYLE_ENDPOINT=false' >> .env && \
    echo 'VITE_APP_NAME="${APP_NAME}"' >> .env

# Configura permisos
RUN chown -R www-data:www-data /var/www/html && \
    chmod -R 755 /var/www/html

# Instala dependencias de Laravel como www-data
USER www-data
RUN composer install --no-interaction --optimize-autoloader --no-dev && \
    composer require laravel/octane && \
    php artisan octane:install --server=swoole

# Vuelve a root para las configuraciones finales
USER root

# Configura permisos adicionales
RUN chmod -R 755 storage bootstrap/cache

EXPOSE 5000

CMD ["php", "artisan", "octane:start", "--server=swoole", "--host=0.0.0.0", "--port=5000"]