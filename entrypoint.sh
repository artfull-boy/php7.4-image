#!/bin/sh
set -e

# Start PHP-FPM in foreground
php-fpm -F &

# Start Nginx in foreground
exec nginx -g 'daemon off;'
