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

# Actualizamos e instalamos PHP y MySQL
RUN apt-get update && apt-get install -y \
    mysql-server \
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

# Configuramos MySQL con el método de autenticación correcto
RUN service mysql start && \
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '1524';" && \
    mysql -e "CREATE DATABASE IF NOT EXISTS cumplimiento_db;" && \
    mysql -e "CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED WITH mysql_native_password BY '1524';" && \
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;" && \
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;" && \
    mysql -e "FLUSH PRIVILEGES;"

# Configuramos MySQL para permitir conexiones externas
RUN sed -i 's/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf && \
    sed -i '/^# settings/a default_authentication_plugin=mysql_native_password' /etc/mysql/mysql.conf.d/mysqld.cnf

WORKDIR /app

COPY . .

# Configuramos el archivo .env
COPY .env.example .env
RUN sed -i 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env && \
    sed -i 's/DB_HOST=.*/DB_HOST=127.0.0.1/' .env && \
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

# Script de inicio mejorado
RUN echo '#!/bin/bash\n\
service mysql start\n\
while ! mysqladmin ping -h"localhost" -u"root" -p"1524" --silent; do\n\
    sleep 1\n\
done\n\
mysql -u root -p1524 -e "ALTER USER '\''root'\''@'\''localhost'\'' IDENTIFIED WITH mysql_native_password BY '\''1524'\''"\n\
mysql -u root -p1524 -e "FLUSH PRIVILEGES"\n\
php artisan migrate:fresh --force\n\
php artisan octane:start --server=swoole --host=0.0.0.0 --port=5000\n\
' > /app/start.sh && chmod +x /app/start.sh

EXPOSE 5000

CMD ["/app/start.sh"]