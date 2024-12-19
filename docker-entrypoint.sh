#!/bin/bash

# Generar clave de la aplicación
php artisan key:generate --force

# Instalar y configurar Octane con Swoole
php artisan octane:install --server=swoole --force

# Ejecutar migraciones
php artisan migrate --force

# Optimizar la aplicación
php artisan optimize
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Iniciar el servidor Octane
php artisan octane:start --server=swoole --host=0.0.0.0 --port=5000