FROM php:8.2-fpm

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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Instala extensiones PHP
RUN docker-php-ext-install \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip

# Instala Swoole deshabilitando brotli y otras extensiones no necesarias
RUN pecl install swoole --enable-brotli=no --enable-sockets=no --enable-openssl=no --enable-http2=no --enable-mysqlnd=no \
    && docker-php-ext-enable swoole

# Instala Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configura el directorio de trabajo
WORKDIR /var/www/html

# Copia los archivos de la aplicación
COPY . .
COPY .env.docker .env

# Instala dependencias de Laravel
RUN composer install --no-interaction --optimize-autoloader --no-dev \
    && composer require laravel/octane \
    && php artisan octane:install --server=swoole

# Configura permisos
RUN chown -R www-data:www-data storage bootstrap/cache \
    && chmod -R 755 storage bootstrap/cache

# Copia y configura el script de inicio
COPY docker/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 5000

ENTRYPOINT ["docker-entrypoint.sh"]