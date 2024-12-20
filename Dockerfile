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
    curl unzip nano software-properties-common \
    wget gnupg2 ca-certificates lsb-release apt-transport-https \
    pkg-config libbrotli-dev libz-dev libpcre3-dev libicu-dev

# Instala MySQL
RUN apt-get install -y mysql-server

# Configura MySQL
RUN mkdir -p /var/run/mysqld && \
    mkdir -p /var/lib/mysql && \
    chown -R mysql:mysql /var/run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql && \
    echo "[mysqld]" >> /etc/mysql/my.cnf && \
    echo "user = mysql" >> /etc/mysql/my.cnf && \
    echo "bind-address = 0.0.0.0" >> /etc/mysql/my.cnf && \
    echo "default-authentication-plugin = mysql_native_password" >> /etc/mysql/my.cnf && \
    echo "skip-host-cache" >> /etc/mysql/my.cnf && \
    echo "skip-name-resolve" >> /etc/mysql/my.cnf

# Agrega el repositorio de PHP 8.2 y lo instala junto con las extensiones requeridas
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

# Establece el directorio de trabajo
WORKDIR /app

# Copia los archivos de la aplicación al contenedor
COPY . .

# Inicia MySQL y configura la base de datos
RUN service mysql start && \
    sleep 5 && \
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '1524';" && \
    mysql -e "CREATE DATABASE IF NOT EXISTS cumplimiento_db;" && \
    mysql -e "CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '1524';" && \
    mysql -e "CREATE USER IF NOT EXISTS 'root'@'127.0.0.1' IDENTIFIED BY '1524';" && \
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;" && \
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;" && \
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;" && \
    mysql -e "FLUSH PRIVILEGES;"

# Copia el archivo .env.example a .env si no existe
RUN if [ ! -f .env ]; then cp .env.example .env; fi

# Configura todas las variables en el archivo .env
RUN sed -i 's/APP_NAME=.*/APP_NAME="Cumplimiento"/' .env && \
    sed -i 's/APP_ENV=.*/APP_ENV=local/' .env && \
    sed -i 's/APP_DEBUG=.*/APP_DEBUG=true/' .env && \
    sed -i 's/APP_URL=.*/APP_URL=http:\/\/localhost/' .env && \
    sed -i 's/LOG_CHANNEL=.*/LOG_CHANNEL=stack/' .env && \
    sed -i 's/LOG_DEPRECATIONS_CHANNEL=.*/LOG_DEPRECATIONS_CHANNEL=null/' .env && \
    sed -i 's/LOG_LEVEL=.*/LOG_LEVEL=debug/' .env && \
    sed -i 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env && \
    sed -i 's/DB_HOST=.*/DB_HOST=127.0.0.1/' .env && \
    sed -i 's/DB_PORT=.*/DB_PORT=3306/' .env && \
    sed -i 's/DB_DATABASE=.*/DB_DATABASE=cumplimiento_db/' .env && \
    sed -i 's/DB_USERNAME=.*/DB_USERNAME=root/' .env && \
    sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=1524/' .env && \
    sed -i 's/BROADCAST_DRIVER=.*/BROADCAST_DRIVER=log/' .env && \
    sed -i 's/CACHE_DRIVER=.*/CACHE_DRIVER=file/' .env && \
    sed -i 's/FILESYSTEM_DISK=.*/FILESYSTEM_DISK=local/' .env && \
    sed -i 's/QUEUE_CONNECTION=.*/QUEUE_CONNECTION=sync/' .env && \
    sed -i 's/SESSION_DRIVER=.*/SESSION_DRIVER=database/' .env && \
    sed -i 's/SESSION_LIFETIME=.*/SESSION_LIFETIME=120/' .env && \
    sed -i 's/MEMCACHED_HOST=.*/MEMCACHED_HOST=127.0.0.1/' .env && \
    sed -i 's/REDIS_HOST=.*/REDIS_HOST=127.0.0.1/' .env && \
    sed -i 's/REDIS_PASSWORD=.*/REDIS_PASSWORD=null/' .env && \
    sed -i 's/REDIS_PORT=.*/REDIS_PORT=6379/' .env && \
    sed -i 's/MAIL_MAILER=.*/MAIL_MAILER=smtp/' .env && \
    sed -i 's/MAIL_HOST=.*/MAIL_HOST=mailpit/' .env && \
    sed -i 's/MAIL_PORT=.*/MAIL_PORT=1025/' .env && \
    sed -i 's/MAIL_USERNAME=.*/MAIL_USERNAME=null/' .env && \
    sed -i 's/MAIL_PASSWORD=.*/MAIL_PASSWORD=null/' .env && \
    sed -i 's/MAIL_ENCRYPTION=.*/MAIL_ENCRYPTION=null/' .env && \
    sed -i 's/MAIL_FROM_ADDRESS=.*/MAIL_FROM_ADDRESS="hello@example.com"/' .env && \
    sed -i 's/MAIL_FROM_NAME=.*/MAIL_FROM_NAME="${APP_NAME}"/' .env && \
    sed -i 's/AWS_ACCESS_KEY_ID=.*/AWS_ACCESS_KEY_ID=/' .env && \
    sed -i 's/AWS_SECRET_ACCESS_KEY=.*/AWS_SECRET_ACCESS_KEY=/' .env && \
    sed -i 's/AWS_DEFAULT_REGION=.*/AWS_DEFAULT_REGION=us-east-1/' .env && \
    sed -i 's/AWS_BUCKET=.*/AWS_BUCKET=/' .env && \
    sed -i 's/AWS_USE_PATH_STYLE_ENDPOINT=.*/AWS_USE_PATH_STYLE_ENDPOINT=false/' .env && \
    sed -i 's/PUSHER_APP_ID=.*/PUSHER_APP_ID=/' .env && \
    sed -i 's/PUSHER_APP_KEY=.*/PUSHER_APP_KEY=/' .env && \
    sed -i 's/PUSHER_APP_SECRET=.*/PUSHER_APP_SECRET=/' .env && \
    sed -i 's/PUSHER_HOST=.*/PUSHER_HOST=/' .env && \
    sed -i 's/PUSHER_PORT=.*/PUSHER_PORT=443/' .env && \
    sed -i 's/PUSHER_SCHEME=.*/PUSHER_SCHEME=https/' .env && \
    sed -i 's/PUSHER_APP_CLUSTER=.*/PUSHER_APP_CLUSTER=mt1/' .env && \
    sed -i 's/VITE_PUSHER_APP_KEY=.*/VITE_PUSHER_APP_KEY="${PUSHER_APP_KEY}"/' .env && \
    sed -i 's/VITE_PUSHER_HOST=.*/VITE_PUSHER_HOST="${PUSHER_HOST}"/' .env && \
    sed -i 's/VITE_PUSHER_PORT=.*/VITE_PUSHER_PORT="${PUSHER_PORT}"/' .env && \
    sed -i 's/VITE_PUSHER_SCHEME=.*/VITE_PUSHER_SCHEME="${PUSHER_SCHEME}"/' .env && \
    sed -i 's/VITE_PUSHER_APP_CLUSTER=.*/VITE_PUSHER_APP_CLUSTER="${PUSHER_APP_CLUSTER}"/' .env && \
    sed -i 's/OCTANE_SERVER=.*/OCTANE_SERVER=swoole/' .env

# Instala las dependencias del proyecto
RUN composer install --no-interaction --optimize-autoloader --no-dev

# Configura los permisos correctos
RUN chown -R www-data:www-data /app && \
    chmod -R 775 storage bootstrap/cache

# Genera la clave de la aplicación
RUN php artisan key:generate --force

# Instala Laravel Octane
RUN composer require laravel/octane --no-interaction

# Instala Octane con Swoole
RUN php artisan octane:install --server=swoole

# Asegura que el storage esté enlazado
RUN php artisan storage:link

# Optimiza la configuración
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

# Crea un script de inicio
RUN echo '#!/bin/bash\n\
service mysql start\n\
while ! mysqladmin ping -h"localhost" --silent; do\n\
    sleep 1\n\
done\n\
php artisan migrate --force\n\
php artisan octane:start --server=swoole --host=0.0.0.0 --port=5000\n\
' > /app/start.sh && chmod +x /app/start.sh

# Expone el puerto 5000
EXPOSE 5000

# Comando para iniciar MySQL, ejecutar migraciones y la aplicación
CMD ["/app/start.sh"]