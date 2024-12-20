#!/bin/bash
set -e

# Espera a que MySQL esté disponible
until nc -z -v -w30 db 3306
do
  echo "Esperando a que la base de datos esté disponible..."
  sleep 2
done
echo "Base de datos disponible"

# Genera la clave de la aplicación si no existe
php artisan key:generate --force

# Ejecuta las migraciones
php artisan migrate --force

# Limpia y optimiza la configuración
php artisan config:clear
php artisan cache:clear
php artisan route:clear
php artisan view:clear
php artisan config:cache

# Inicia Octane
php artisan octane:start --server=swoole --host=0.0.0.0 --port=8000

exec "$@"