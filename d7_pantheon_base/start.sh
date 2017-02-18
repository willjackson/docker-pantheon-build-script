#!/bin/bash

# Start Apache and MySQL
service apache2 start
service mysql start

tar -zxf /tmp/assets/backup.code.tar.gz -C /var/www/html/ --strip 1
mkdir /var/www/html/sites/default/files
tar -zxf /tmp/assets/backup.files.tar.gz -C /var/www/html/sites/default/files/ --strip 1
chmod -R 777 /var/www/html/sites/default/files
drush si standard --root=/var/www/html --db-url='mysql://root:root123!@localhost/drupal7' -y
drush --root=/var/www/html/ sqlc < /tmp/assets/backup.db.sql
chmod -R 777 /var/www/html/sites/default/files/
