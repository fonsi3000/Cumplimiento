#!/bin/bash

php artisan key:generate --force
php artisan octane:install --server=swoole --force
php artisan migrate --force
php artisan optimize
php artisan octane:start --server=swoole --host=0.0.0.0 --port=5000