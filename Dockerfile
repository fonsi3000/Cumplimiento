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
RUN pecl install swoole --enable-brotli=no --enable-sockets=no --enable-openssl=no --enable-http2=no --enable-mysqlnd=no
RUN docker-php-ext-enable swoole

# Instala Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configura el directorio de trabajo
WORKDIR /var/www/html

# Copia los archivos de la aplicación
COPY . .
COPY .env.docker .env

# Configura permisos antes de la instalación
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

# Copia y configura el script de inicio
COPY docker/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 5000

ENTRYPOINT ["docker-entrypoint.sh"]