# Dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Bogota
ENV COMPOSER_ALLOW_SUPERUSER=1

# Instalamos paquetes esenciales primero
RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    wget \
    gnupg2 \
    ca-certificates \
    lsb-release \
    apt-transport-https \
    unzip \
    pkg-config \
    libbrotli-dev \
    libz-dev \
    libpcre3-dev \
    libicu-dev \
    git \
    && rm -rf /var/lib/apt/lists/*

# Agregamos el repositorio de PHP
RUN add-apt-repository ppa:ondrej/php -y

# Actualizamos e instalamos PHP y extensiones necesarias
RUN apt-get update && apt-get install -y \
    php8.2 \
    php8.2-cli \
    php8.2-common \
    php8.2-mysql \
    php8.2-zip \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-curl \
    php8.2-xml \
    php8.2-bcmath \
    php8.2-dev \
    php8.2-intl \
    php8.2-dom \
    php8.2-fileinfo \
    php8.2-tokenizer \
    && rm -rf /var/lib/apt/lists/*

# Instalamos Swoole deshabilitando brotli
RUN pecl channel-update pecl.php.net && \
    pecl install --configureoptions 'enable-brotli="no"' swoole && \
    echo "extension=swoole.so" > /etc/php/8.2/cli/conf.d/swoole.ini && \
    echo "extension=swoole.so" > /etc/php/8.2/cli/conf.d/20-swoole.ini

# Instalamos Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /app

# Copiamos los archivos de composer primero
COPY composer.json composer.lock ./

# Instalamos las dependencias
RUN composer install --no-dev --optimize-autoloader --no-interaction --no-scripts

# Copiamos el resto de la aplicación
COPY . .

# Establecemos los permisos correctos
RUN chmod -R 775 storage bootstrap/cache && \
    chown -R www-data:www-data /app

# Configuramos el archivo .env
RUN cp .env.example .env && \
    sed -i 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env && \
    sed -i 's/DB_HOST=.*/DB_HOST=db/' .env && \
    sed -i 's/DB_PORT=.*/DB_PORT=3306/' .env && \
    sed -i 's/DB_DATABASE=.*/DB_DATABASE=cumplimiento_db/' .env && \
    sed -i 's/DB_USERNAME=.*/DB_USERNAME=root/' .env && \
    sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=1524/' .env

# Generamos la key e instalamos Octane
RUN php artisan key:generate && \
    composer require laravel/octane --no-interaction && \
    php artisan octane:install --server=swoole

# Optimizaciones finales
RUN php artisan optimize:clear && \
    php artisan optimize && \
    php artisan view:cache

EXPOSE 5000

CMD ["php", "artisan", "octane:start", "--server=swoole", "--host=0.0.0.0", "--port=5000"]