#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing Docker..."

    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER

    echo "Docker installed successfully."
else
    echo "Docker is already installed."
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose not found. Installing Docker Compose..."

    # Install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    echo "Docker Compose installed successfully."
else
    echo "Docker Compose is already installed."
fi

# Check if site name is provided as command-line argument
if [ -z "$1" ]; then
    echo "Please provide a site name as a command-line argument."
    exit 1
fi

site_name="$1"

# Create a new directory for the LEMP stack
mkdir "$site_name"
cd "$site_name"

# Create a docker-compose.yml file for the LEMP stack
cat <<EOF > docker-compose.yml
version: '3'

services:
  nginx:
    image: nginx:latest
    ports:
      - 80:80
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./nginx/html:/var/www/html
    depends_on:
      - php
  mysql:
    image: mysql:5.7
    environment:
      MYSQL_ROOT_PASSWORD: example
      MYSQL_DATABASE: $site_name
    volumes:
      - ./mysql:/var/lib/mysql
  php:
    image: php:7.4-fpm
    volumes:
      - ./php:/var/www/html
EOF

# Create directories for Nginx, MySQL, and PHP
mkdir -p nginx/conf.d nginx/html mysql php

# Create an Nginx configuration file
cat <<EOF > nginx/conf.d/default.conf
server {
    listen 80;
    server_name $site_name;

    location / {
        root /var/www/html;
        index index.php index.html;
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass php:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_buffers 16 16k;
        fastcgi_buffer_size 32k;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Start the LEMP stack
docker-compose up -d
echo "LEMP stack created successfully. You can access your website at http://localhost"
chmod +x create_lemp_stack.sh
./create_lemp_stack.sh mysite
