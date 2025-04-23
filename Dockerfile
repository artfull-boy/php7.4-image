# syntax=docker/dockerfile:1

# 1) Base image: PHP 7.4 FPM
FROM php:7.4-fpm

USER root

# 2) Install system packages, Nginx, clients, and PHP extensions
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

# 3) Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-configure ldap \
 && docker-php-ext-install \
      bcmath \
      gd \
      intl \
      ldap \
      mbstring \
      mysqli \
      opcache \
      pdo_mysql \
      pdo_pgsql \
      pgsql \
      soap \
      xml \
      gmp \
      zip

# 4) APCu & Memcached via PECL
RUN pecl install apcu \
    && docker-php-ext-enable apcu \
    && pecl install memcached \
    && docker-php-ext-enable memcached

# 5) Imagick via PECL
RUN pecl install imagick \
    && docker-php-ext-enable imagick

# 6) Install specific Composer version (2.5.4)
RUN wget -O composer-setup.php https://getcomposer.org/installer \
    && php composer-setup.php --install-dir=/usr/local/bin --filename=composer --version=2.5.4 \
    && rm composer-setup.php

# 7) Install Drush 8.1.12 globally
RUN composer global require drush/drush:8.1.12 \
    && ln -s /root/.composer/vendor/bin/drush /usr/local/bin/drush

# 8) Copy Nginx and PHP-FPM pool configs
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./www.conf   /usr/local/etc/php-fpm.d/www.conf

# 9) Create webroot and set permissions
RUN mkdir -p /var/www/html \
    && chown -R www-data:www-data /var/www/html

WORKDIR /var/www/html

# 10) Expose port and add entrypoint
EXPOSE 8080
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
