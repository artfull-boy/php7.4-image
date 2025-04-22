FROM nginx:latest

USER root

# Add repository for PHP 7.4
RUN apt-get update && apt-get install -y software-properties-common \
    && add-apt-repository -y ppa:ondrej/php \
    && apt-get update

# Install PHP 7.4 packages
RUN apt-get install -y \
    php7.4-cli \
    php7.4-fpm \
    php7.4-mysql \
    php7.4-pgsql \
    php7.4-bcmath \
    php7.4-gd \
    php7.4-intl \
    php7.4-ldap \
    php7.4-mbstring \
    php7.4-pdo \
    php7.4-soap \
    php7.4-opcache \
    php7.4-xml \
    php7.4-gmp \
    php7.4-apcu \
    php7.4-zip \
    php7.4-memcached \
    libnss-wrapper \
    dnsutils \
    gettext \
    hostname \
    supervisor \
    ghostscript \
    php7.4-imagick \
    fonts-liberation \
    libxaw7 \
    graphviz \
    libwmf-bin \
    imagemagick \
    unzip \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

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
    && chown -R nginx:nginx /var/cache/nginx \
    && mkdir -p /var/lib/nginx/logs \
    && chown -R nginx:nginx /var/lib/nginx \
    && mkdir -p /run \
    && chmod 1777 /run

# Remove default NGINX config
RUN rm -f /etc/nginx/conf.d/default.conf

# Create directories for PHP 7.4 FPM
RUN mkdir -p /etc/php/7.4/fpm/pool.d

# Copy configuration files
COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Update supervisord.conf to use PHP 7.4
RUN sed -i "s|command=php-fpm|command=/usr/sbin/php-fpm7.4|g" /etc/supervisor/conf.d/supervisord.conf

# Copy PHP-FPM pool configuration
COPY ./www.conf /etc/php/7.4/fpm/pool.d/www.conf

# Install specific Drush version (8.1.12)
RUN composer global require drush/drush:8.1.12 \
    && echo 'export PATH="$PATH:$HOME/.composer/vendor/bin"' >> /root/.bashrc \
    && ln -s /root/.composer/vendor/bin/drush /usr/local/bin/drush

# Set working directory for when code is uploaded
WORKDIR /var/www/html

# Fix permissions - add nginx user to www-data group
RUN usermod -a -G www-data nginx

# Verify file permissions are correct
RUN mkdir -p /var/www/html \
    && chown -R nginx:nginx /var/www/html

EXPOSE 8080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]