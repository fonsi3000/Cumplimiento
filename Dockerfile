# Usa Ubuntu 22.04 como imagen base
FROM ubuntu:22.04

# Evita interacciones durante la instalación de paquetes
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Bogota

# Actualiza el sistema e instala paquetes necesarios
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y bash git sudo openssh-client \
    libxml2-dev libonig-dev autoconf gcc g++ make npm \
    libfreetype6-dev libjpeg-turbo8-dev libpng-dev libzip-dev \
    curl unzip nano software-properties-common mysql-server

# Agrega el repositorio de PHP 8.2 y lo instala junto con las extensiones
RUN add-apt-repository ppa:ondrej/php -y && \
    apt-get update && \
    apt-get install -y php8.2 php8.2-fpm php8.2-cli php8.2-common \
    php8.2-mysql php8.2-zip php8.2-gd php8.2-mbstring php8.2-curl php8.2-xml php8.2-bcmath \
    php8.2-intl php8.2-readline php8.2-pcov php8.2-dev

# Instala Swoole desde PECL
RUN pecl install swoole && \
    echo "extension=swoole.so" > /etc/php/8.2/mods-available/swoole.ini && \
    phpenmod swoole

# Instala Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Configura MySQL
RUN service mysql start && \
    sleep 5 && \
    mysql -e "CREATE DATABASE cumplimiento_db;" && \
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Espumas';" && \
    mysql -e "CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'Espumas';" && \
    mysql -e "CREATE USER IF NOT EXISTS 'root'@'127.0.0.1' IDENTIFIED BY 'Espumas';" && \
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;" && \
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;" && \
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;" && \
    mysql -e "FLUSH PRIVILEGES;"

# Establece el directorio de trabajo
WORKDIR /app

# Copia los archivos de la aplicación
COPY . .

# Copia y configura el archivo .env
COPY .env.example .env

# Configura el archivo .env
RUN sed -i 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env && \
    sed -i 's/DB_HOST=.*/DB_HOST=127.0.0.1/' .env && \
    sed -i 's/DB_PORT=.*/DB_PORT=3306/' .env && \
    sed -i 's/DB_DATABASE=.*/DB_DATABASE=cumplimiento_db/' .env && \
    sed -i 's/DB_USERNAME=.*/DB_USERNAME=root/' .env && \
    sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=Espumas/' .env && \
    sed -i 's/SESSION_DRIVER=.*/SESSION_DRIVER=database/' .env

# Instala dependencias y configura Laravel
RUN composer install --no-interaction --optimize-autoloader --no-dev && \
    php artisan key:generate --force && \
    composer require laravel/octane && \
    php artisan octane:install --server=swoole

# Configura permisos
RUN chown -R www-data:www-data /app && \
    chmod -R 775 storage bootstrap/cache

# Script de inicio
RUN echo '#!/bin/bash\n\
service mysql start\n\
while ! mysqladmin ping -h"localhost" -u"root" -p"Espumas" --silent; do\n\
    echo "Esperando que MySQL inicie..."\n\
    sleep 2\n\
done\n\
php artisan migrate --force\n\
php artisan config:clear\n\
php artisan cache:clear\n\
php artisan route:clear\n\
php artisan view:clear\n\
php artisan config:cache\n\
php artisan octane:start --server=swoole --host=0.0.0.0 --port=5000\n\
' > /app/start.sh && chmod +x /app/start.sh

EXPOSE 5000

CMD ["/app/start.sh"]