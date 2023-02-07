# default wordpress version to install
ARG WORDPRESS_VARIANT="6.1.1-php8.1-fpm"

# https://hub.docker.com/_/wordpress
FROM wordpress:${WORDPRESS_VARIANT}

LABEL maintainer="Drew Gauderman <drew@dpg.host>" \
    Description="PHP Dev with WP CLI with addtional site setup options."

# disable wp-cli root messages
ENV WP_CLI_ALLOW_ROOT true
ENV WORDPRESS_DEBUG false

# install required software
RUN set -ex;\
    apt update;\
    apt -y install curl mariadb-client;

# # install nvm for node
# RUN nvm install node;\
#     nvm install-latest-npm;

# # install the PHP extensions we need for wp-cli
# RUN set -ex; \
#     docker-php-ext-install -j "$(nproc)" \
#     mysqli;

#install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

#XDebug settings
# RUN echo "[XDebug]\nxdebug.remote_enable = 1\nxdebug.remote_autostart = 1" > $PHP_INI_DIR/conf.d/xdebug.ini

# script that runs on launch
COPY ./docker-entrypoint.sh /usr/local/bin/

# give permissions for docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# work dir
WORKDIR /var/www/html

ENTRYPOINT [ "/usr/local/bin/docker-entrypoint.sh" ]
