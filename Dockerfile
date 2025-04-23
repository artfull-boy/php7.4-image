FROM php:7.4-fpm

# Install nginx and other dependencies
RUN apt-get update && apt-get install -y \
    nginx \
    default-mysql-client \
    postgresql-client \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libpq-dev \
    libzip-dev \
    libicu-dev \
    libldap2-dev \
    libxml2-dev \
    libgmp-dev \
    libmemcached-dev \
    libnss-wrapper \
    dnsutils \
    gettext \
    hostname \
    supervisor \
    ghostscript \
    fonts-liberation \
    libxaw7 \
    graphviz \
    libwmf-bin \
    imagemagick \
    unzip \
    wget \
    libonig-dev \
    pkg-config \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure GD extension
RUN docker-php-ext-configure gd --with-freetype --with-jpeg

# Configure LDAP properly
RUN apt-get update && apt-get install -y libldap2-dev \
    && ln -s /usr/lib/x86_64-linux-gnu/libldap.so /usr/lib/libldap.so \
    && ln -s /usr/lib/x86_64-linux-gnu/liblber.so /usr/lib/liblber.so \
    && docker-php-ext-configure ldap

# Install PHP extensions one by one to better identify any issues
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install gd
RUN docker-php-ext-install intl
RUN docker-php-ext-install ldap
RUN docker-php-ext-install mbstring
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install opcache
RUN docker-php-ext-install pdo_mysql
RUN docker-php-ext-install pdo_pgsql
RUN docker-php-ext-install pgsql
RUN docker-php-ext-install soap
RUN docker-php-ext-install xml
RUN docker-php-ext-install gmp
RUN docker-php-ext-install zip

# Install APCu and Memcached
RUN pecl install apcu \
    && docker-php-ext-enable apcu
    
RUN apt-get update && apt-get install -y libmemcached-dev zlib1g-dev \
    && pecl install memcached \
    && docker-php-ext-enable memcached

# Install Imagick
RUN apt-get update && apt-get install -y libmagickwand-dev \
    && pecl install imagick \
    && docker-php-ext-enable imagick

# Install specific Composer version (2.5.4)
RUN wget -O composer-setup.php https://getcomposer.org/installer \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer --version=2.5.4 \
    && rm composer-setup.php

# Create required directories with proper permissions
RUN mkdir -p /var/run/php \
    && mkdir -p /var/cache/nginx/client_temp \
    && mkdir -p /var/cache/nginx/proxy_temp \
    && mkdir -p /var/cache/nginx/fastcgi_temp \
    && mkdir -p /var/cache/nginx/uwsgi_temp \
    && mkdir -p /var/cache/nginx/scgi_temp \
    && chown -R www-data:www-data /var/cache/nginx \
    && mkdir -p /var/lib/nginx/logs \
    && chown -R www-data:www-data /var/lib/nginx \
    && mkdir -p /run \
    && chmod 1777 /run

# Remove default NGINX config
RUN rm -f /etc/nginx/sites-enabled/default

# Copy configuration files
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./supervisord.conf /etc/supervisor/supervisord.conf
COPY ./www.conf /usr/local/etc/php-fpm.d/www.conf

# Install specific Drush version (8.1.12)
RUN composer global require drush/drush:8.1.12 \
    && echo 'export PATH="$PATH:$HOME/.composer/vendor/bin"' >> /root/.bashrc \
    && ln -s /root/.composer/vendor/bin/drush /usr/local/bin/drush

# Set working directory for when code is uploaded
WORKDIR /var/www/html

# Fix permissions
RUN mkdir -p /var/www/html \
    && chown -R www-data:www-data /var/www/html

EXPOSE 8080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]