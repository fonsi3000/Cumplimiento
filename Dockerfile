# Dockerfile
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Bogota

# Instalamos paquetes esenciales
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
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
    sudo \
    openssh-client \
    libxml2-dev \
    libonig-dev \
    autoconf \
    gcc \
    g++ \
    make \
    libfreetype6-dev \
    libjpeg-turbo8-dev \
    libpng-dev \
    libzip-dev

# Instala Node.js de manera correcta para que soporte las versiones requeridas
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
    apt-get update && \
    apt-get install -y nodejs && \
    npm install -g npm@latest

# Instala y configura MySQL
RUN apt-get install -y mysql-server && \
    mkdir -p /var/run/mysqld && \
    mkdir -p /var/lib/mysql && \
    chown -R mysql:mysql /var/run/mysqld && \
    chown -R mysql:mysql /var/lib/mysql && \
    echo "[mysqld]" >> /etc/mysql/my.cnf && \
    echo "user = mysql" >> /etc/mysql/my.cnf && \
    echo "bind-address = 0.0.0.0" >> /etc/mysql/my.cnf && \
    echo "default-authentication-plugin = mysql_native_password" >> /etc/mysql/my.cnf && \
    echo "skip-host-cache" >> /etc/mysql/my.cnf && \
    echo "skip-name-resolve" >> /etc/mysql/my.cnf && \
    service mysql start && \
    sleep 5 && \
    # Configurar la contraseña de root y privilegios
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '1524';" && \
    mysql -e "CREATE DATABASE IF NOT EXISTS cumplimiento_db;" && \
    mysql -e "CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '1524';" && \
    mysql -e "CREATE USER IF NOT EXISTS 'root'@'127.0.0.1' IDENTIFIED BY '1524';" && \
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;" && \
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;" && \
    mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;" && \
    mysql -e "FLUSH PRIVILEGES;"

# Agrega el repositorio de PHP e instala PHP y extensiones
RUN add-apt-repository ppa:ondrej/php -y && \
    apt-get update && \
    apt-get install -y php8.2 php8.2-fpm php8.2-cli php8.2-common \
    php8.2-mysql php8.2-zip php8.2-gd php8.2-mbstring php8.2-curl php8.2-xml php8.2-bcmath \
    php8.2-intl php8.2-readline php8.2-pcov php8.2-dev

# Instala Swoole
RUN pecl install swoole && \
    echo "extension=swoole.so" > /etc/php/8.2/mods-available/swoole.ini && \
    phpenmod swoole

# Instala Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Establece el directorio de trabajo
WORKDIR /app

# Copia todos los archivos del proyecto, incluyendo start.sh
COPY . .

# Copia los archivos del proyecto
COPY . /app/

# Configura el archivo .env
COPY .env.example /app/.env
RUN sed -i 's/DB_CONNECTION=.*/DB_CONNECTION=mysql/' .env && \
    sed -i 's/DB_HOST=.*/DB_HOST=127.0.0.1/' .env && \
    sed -i 's/DB_PORT=.*/DB_PORT=3306/' .env && \
    sed -i 's/DB_DATABASE=.*/DB_DATABASE=cumplimiento_db/' .env && \
    sed -i 's/DB_USERNAME=.*/DB_USERNAME=root/' .env && \
    sed -i 's/DB_PASSWORD=.*/DB_PASSWORD=1524/' .env && \
    sed -i 's/SESSION_DRIVER=.*/SESSION_DRIVER=database/' .env

# Instala dependencias de PHP
RUN composer install --no-interaction --optimize-autoloader --no-dev

# Instala Octane
RUN composer require laravel/octane --no-interaction && \
    php artisan octane:install --server=swoole

# Instala dependencias de Node.js y construye los assets
RUN npm install && npm run build

# Configura permisos finales
RUN chown -R www-data:www-data /app && \
    chmod -R 775 storage bootstrap/cache

# Genera la key de la aplicación
RUN php artisan key:generate --force

# Verifica la existencia del script de inicio nuevamente
RUN ls -la /app/start.sh && \
    cat /app/start.sh

EXPOSE 5000

CMD ["./start.sh"]