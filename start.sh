php artisan migrate --force
php artisan optimize:clear
php artisan optimize
php artisan octane:start --server=swoole --host=0.0.0.0 --port=5000