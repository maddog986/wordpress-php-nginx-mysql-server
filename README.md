# WordPress Docker PHP Nginx MySQL v1.0.5

This repo is designed to make it easy to setup and run a WordPress website for developement.

This will setup a [MariaDB](https://mariadb.com/) (MySQL) database, [WordPress](https://wordpress.com] (PHP-FPM-Alpine) & [WP-CLI](https://wp-cli.org/), and uses [NGINX](https://www.nginx.com/).

## Environment Variables:

See the .env.sample file for all environment variables. This is where you can make your WordPress install changes. You should not have to edit the docker-compose.yml file.

## Notes

Site backup import:
    You can specify a URL to download a site backup and have it imported upon first container boot by specifying BACKUP_SITE_DOWNLOAD varaible and optional (recommended) http auth password BACKUP_PASSWORD.

    When the site is downloaded, you can include extra nginx conf files to be excuted. example: for custom redirects, so you dont have to import wp-content/uploads

    Notes about the site download:
    - *.conf files within the root www folder will automatically be included in ngnix default.conf. These files can extend the site settings.
    - *.sql files within the root are executed after mysql database setup upon container first boot only. These files are used to restore a database to the server and are deleted once imported.

## License

The MIT License (MIT)

Copyright (c) 2019-2023 Drew Gauderman

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
