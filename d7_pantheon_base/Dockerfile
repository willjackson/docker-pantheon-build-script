# Custom build instructions for Drupal 7
FROM willjackson/d7-pantheon-base
MAINTAINER Will Jackson <willjackson00@gmail.com>

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

# Copy startup script.
COPY start.sh /tmp/

# Create assets directory
CMD mkdir -p /tmp/assets

# Copy assets directory
COPY assets/* /tmp/assets/

ENTRYPOINT chmod +x /tmp/start.sh && sync && /tmp/start.sh && bash

# Set work directory
WORKDIR "/var/www/html"
