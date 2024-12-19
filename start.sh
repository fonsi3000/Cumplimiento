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
    if mysqladmin ping -h"localhost" -u"root" -p"1524" --silent; then
        break
    fi
    echo "Waiting for MySQL to be ready... $i/30"
    sleep 1
done

# Ejecuta las migraciones
echo "Running migrations..."
php artisan migrate --force

# Optimiza la aplicación
php artisan optimize:clear
php artisan optimize

# Inicia Laravel Octane
echo "Starting Laravel Octane..."
php artisan octane:start --server=swoole --host=0.0.0.0 --port=5000