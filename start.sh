#!/bin/bash

# Asegura los directorios de MySQL
mkdir -p /var/run/mysqld
mkdir -p /var/lib/mysql
chown -R mysql:mysql /var/run/mysqld
chown -R mysql:mysql /var/lib/mysql

# Inicia MySQL
service mysql start
status=$?
if [ $status -ne 0 ]; then
    echo "Failed to start MySQL: $status"
    exit $status
fi

# Espera a que MySQL esté disponible
echo "Waiting for MySQL to be ready..."
for i in {1..30}; do
    if mysqladmin ping -h"localhost" --silent; do
        break
    fi
    echo "Waiting for MySQL to be ready... $i/30"
    sleep 1
done

# Asegura que el usuario existe y tiene los permisos correctos
mysql -e "CREATE USER IF NOT EXISTS 'luiscarrascal'@'%' IDENTIFIED BY '1524';"
mysql -e "GRANT ALL PRIVILEGES ON cumplimiento_db.* TO 'luiscarrascal'@'%';"
mysql -e "FLUSH PRIVILEGES;"

# Prepara la base de datos
php artisan migrate:fresh --force

# Optimiza la aplicación
php artisan optimize:clear
php artisan config:clear
php artisan cache:clear
php artisan optimize

# Inicia Laravel Octane
echo "Starting Laravel Octane..."
php artisan octane:start --server=swoole --host=0.0.0.0 --port=5000