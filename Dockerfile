FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Bogota

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
    && rm -rf /var/lib/apt/lists/*

# Instalamos Swoole deshabilitando brotli
RUN pecl channel-update pecl.php.net && \
    pecl install --configureoptions 'enable-brotli="no"' swoole && \
    echo "extension=swoole.so" > /etc/php/8.2/cli/conf.d/swoole.ini

# Instalamos Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /app

COPY . .
COPY .env.example .env

# Configuramos el archivo .env
RUN sed -i 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env && \
    sed -i 's/DB_HOST=.*/DB_HOST=db/' .env && \
    sed -i 's/DB_PORT=.*/DB_PORT=3306/' .env && \
    sed -i 's/DB_DATABASE=.*/DB_DATABASE=cumplimiento_db/' .env && \
    sed -i 's/DB_USERNAME=.*/DB_USERNAME=root/' .env && \
    sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=1524/' .env

# Instalamos dependencias de Composer
RUN composer install --no-dev --optimize-autoloader

# Generamos la key de la aplicación
RUN php artisan key:generate

# Instalamos Octane
RUN composer require laravel/octane --no-interaction \
    && php artisan octane:install --server=swoole

# Configuramos permisos
RUN chmod -R 775 storage bootstrap/cache

# Copiamos y configuramos el script de inicio
COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

EXPOSE 5000

CMD ["/app/start.sh"]