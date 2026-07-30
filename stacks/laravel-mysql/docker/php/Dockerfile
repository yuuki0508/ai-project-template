# Node は Vite（フロントのビルド）用。PHPイメージに同じalpineベースからコピーする。
FROM __NODE_IMAGE__ AS node

FROM __PHP_IMAGE__

RUN apk add --no-cache git unzip icu-dev oniguruma-dev libzip-dev mysql-client libstdc++ libgcc \
 && docker-php-ext-install pdo_mysql bcmath intl zip opcache

COPY --from=node /usr/local/bin/node /usr/local/bin/node
COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -sf /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
 && ln -sf /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html
