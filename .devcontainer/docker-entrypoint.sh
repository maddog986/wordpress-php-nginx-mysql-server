#!/bin/bash

# disable output if no files
shopt -s nullglob

# make sure codespaces environment variables are loaded and working
if [ -f "/workspaces/.codespaces/shared/.env" ]; then
    source /workspaces/.codespaces/shared/.env
fi

# setup wordpress cli only if ~/.wp-cli/config.yml not defined
[ ! -f ~/.wp-cli/config.yml ] && mkdir ~/.wp-cli

# update permissions
chown -R www-data:www-data /var/www
chmod -R a+rw /var/www/html

# change to wwwroot folder for wp commands
cd /var/www/html

# set dev url
DEV_URL=${DEV_URL:=http://localhost}
# support for different ports other than 80
[ "${DEV_PORT}" != "80" ] && DEV_URL="${DEV_URL}:${DEV_PORT}"
# support for codespaces
[[ -n "${CODESPACE_NAME}" ]] && DEV_URL="https://${CODESPACE_NAME}-${DEV_PORT}.githubpreview.dev"

# saving website url to environment
if ! grep -q DEV_URL "/etc/bash.bashrc"; then
    echo "export DEV_URL=\"${DEV_URL}\"" >>/etc/bash.bashrc
fi

# make sure php-fpm is running
php-fpm -D

# if /var/www/html/.setup-complete exists then skip this script
if [ -f "/var/www/html/.setup-complete" ]; then
    echo "Skipping setup script since /var/www/html/.setup-complete exists. $DEV_URL"
    exec "$@"
    sleep infinity
fi

# setup url and path for wp-cli
echo -e "path: /var/www/html\nurl: ${DEV_URL}" >~/.wp-cli/config.yml

# download site backup if not already installed
if [ -n "$BACKUP_SITE_DOWNLOAD" ] && [ ! -d "/var/www/site.zip" ]; then
    BACKUP_EXCLUDE=${BACKUP_EXCLUDE:-"\"*.sql\""}

    echo "Downloading site from: $BACKUP_SITE_DOWNLOAD."

    # download using url
    curl --user ${BACKUP_USERNAME:-}:$BACKUP_PASSWORD -o /var/www/site.zip -fSL "$BACKUP_SITE_DOWNLOAD"

    echo "Done downloading site."

    echo "Unzipping files to: /var/www/html. This may take awhile..."
    unzip -nq /var/www/site.zip -x $BACKUP_EXCLUDE -d /var/www/html/
    echo "done."

    echo "Unzipping .sql files to: /var/www/db/. This may take awhile... "
    mkdir /var/www/db/
    unzip -nq /var/www/site.zip "*.sql" -x "*/*.sql" -d /var/www/db/
    echo "done."

    # fix any permission issues from unzipping files
    chown -R www-data:www-data /var/www
    chmod -R a+rw /var/www/html

    # import the .sql scripts if any
    for f in /var/www/db/*.sql; do
        # wait until mysql is up and running
        until mysql -h $WORDPRESS_DB_HOST -P 3306 -D $WORDPRESS_DB_NAME -u $WORDPRESS_DB_USER -p$WORDPRESS_DB_PASSWORD -e '\q'; do
            echo >&2 "Mysql is unavailable - sleeping..."
            sleep 1
        done

        echo "Importing .SQL file: $f... "
        /usr/bin/mysql -h $WORDPRESS_DB_HOST -P 3306 -D $WORDPRESS_DB_NAME -u$WORDPRESS_DB_USER -p$WORDPRESS_DB_PASSWORD $WORDPRESS_DB_NAME <"$f"
        echo "done importing sql file $f."
    done

    # clean up imported/downloaded files
    rm -rf /var/www/db /var/www/site.zip
fi

# wait until mysql is up and running
until mysql -h $WORDPRESS_DB_HOST -P 3306 -D $WORDPRESS_DB_NAME -u $WORDPRESS_DB_USER -p$WORDPRESS_DB_PASSWORD -e '\q'; do
    echo >&2 "Mysql is unavailable - sleeping..."
    sleep 1
done

# check to see if WordPress is already installed or not
if $(wp core is-installed); then
    echo "Updating Wordpress Database..."

    # download and install specified version of WordPress
    wp core download --version=${WORDPRESS_VERSION:-latest} --force

    # make sure database is up to date
    wp core update-db
else
    echo "Installing latest WordPress version"

    # download wordpress if not already done
    if [ ! -f "/var/www/html/wp-cron.php" ]; then
        # download and install new version of WordPress
        wp core download --version=${WORDPRESS_VERSION:-latest} --force

        # new wordpress install so setup config file
        if [ -f /var/www/html/wp-config-sample.php ] && [ ! -f /var/www/html/wp-config.php ]; then
            # create the config file from sample
            mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
        fi
    fi

    wp core install --url="$DEV_URL" --title="$WORDPRESS_TITLE" --admin_user="$WORDPRESS_ADMIN_USERNAME" --admin_password="$WORDPRESS_ADMIN_PASSWORD" --admin_email="$WORDPRESS_ADMIN_EMAIL" --skip-email
fi

# set/update wp-config.php values
wp config shuffle-salts
# wp config set DB_HOST $WORDPRESS_DB_HOST
# wp config set DB_NAME $WORDPRESS_DB_NAME
# wp config set DB_USER $WORDPRESS_DB_USER
# wp config set DB_PASSWORD $WORDPRESS_DB_PASSWORD
# wp config set table_prefix $WORDPRESS_TABLE_PREFIX
wp config set FORCE_SSL_ADMIN "$([[ $DEV_URL =~ "https" ]] && echo true || echo false)" --raw # set FORCE_SSL_ADMIN to true if https is used
wp option update siteurl "$DEV_URL"
wp option update home "$DEV_URL"
wp config set DISABLE_CRON ${WORDPRESS_DISABLE_CRON:-false} --raw
wp config set FS_METHOD ${WORDPRESS_FS_METHOD:-"direct"}

# set dynamic url if needed
if [ -n "$WORDPRESS_DYNAMIC_URL" ]; then
    wp config set WP_HOME_DIR "/"
    wp config set WP_SITEURL "/"
    wp config set COOKIE_DOMAIN ""
else
    COOKIE_DOMAIN="$(echo $DEV_URL | sed 's~:[[:digit:]]\+~~g' | sed 's/https\?:\/\///' | sed 's/:$//')" # remove port and protocol
    wp config set COOKIE_DOMAIN $COOKIE_DOMAIN
fi

# some basic wordpress settings
[ -n "$WORDPRESS_ADMIN_EMAIL" ] && wp option update admin_email $WORDPRESS_ADMIN_EMAIL
[ -n "$WORDPRESS_INSTALL_THEME" ] && wp theme install $WORDPRESS_INSTALL_THEME --activate
[ -n "$WORDPRESS_INSTALL_PLUGIN" ] && wp plugin install $WORDPRESS_INSTALL_PLUGIN --activate
[ -n "$WORDPRESS_ACTIVATE_THEME" ] && wp theme activate $WORDPRESS_ACTIVATE_THEME
[ -n "$WORDPRESS_ACTIVATE_PLUGIN" ] && wp plugin activate $WORDPRESS_ACTIVATE_PLUGIN
[ -n "$WORDPRESS_DEACTIVATE_PLUGIN" ] && wp plugin deactivate $WORDPRESS_DEACTIVATE_PLUGIN

touch /var/www/html/.setup-complete

echo "Done with Site Setup! $DEV_URL"

# make sure vscode user has permissions
# usermod -aG www-data vscode

# update permissions
chown -R www-data:www-data /var/www
chmod -R a+rw /var/www/html

# # change user
# su - vscode

exec "$@"
