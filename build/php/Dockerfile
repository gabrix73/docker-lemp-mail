FROM php:8.3-fpm-alpine

# Dipendenze sistema
RUN apk add --no-cache \
    icu-dev \
    libzip-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev \
    oniguruma-dev \
    imagemagick-dev \
    $PHPIZE_DEPS

# Estensioni PHP
RUN docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp && \
    docker-php-ext-install -j$(nproc) \
        pdo_mysql \
        mysqli \
        gd \
        zip \
        intl \
        mbstring \
        exif \
        bcmath \
        opcache \
        sockets

# Imagick (WordPress)
RUN pecl install imagick && docker-php-ext-enable imagick

# APCu (cache oggetti WordPress)
RUN pecl install apcu && docker-php-ext-enable apcu

# Pulizia
RUN apk del $PHPIZE_DEPS && rm -rf /tmp/pear

WORKDIR /var/www
