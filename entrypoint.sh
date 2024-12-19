#!/bin/bash
set -e

echo "Waiting for database connection..."
while ! nc -z db 3306; do
  sleep 1
done

echo "Generating application key..."
php artisan key:generate --force

echo "Running migrations..."
php artisan migrate --force

echo "Optimizing Laravel..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

echo "Starting Octane server..."
php artisan octane:start --server=swoole --host=0.0.0.0 --port=5000 --workers=4 --task-workers=2 --max-requests=1000