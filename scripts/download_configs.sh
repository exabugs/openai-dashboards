#!/bin/bash
set -e

# # Doctor
# curl -fsSL $SERVER_SETUP_SITE/install/docter.sh -o /root/docter.sh
# chmod +x /root/docter.sh

# Apps
apps=(
)
for app in "${apps[@]}"; do
  filepath=/etc/$app
  mkdir -p $(dirname "$filepath")
  curl -fsSL $SERVER_SETUP_SITE$filepath -o $filepath
done

# docker compose
mkdir -p /opt/compose
curl -fsSL $SERVER_SETUP_SITE/compose/docker-compose.yml -o /opt/compose/docker-compose.yml

# Nginx sites
mkdir -p /etc/nginx/sites-available
available=(
  default
  openai
)
for site in "${available[@]}"; do
  path=/etc/nginx/sites-available/$site
  curl -fsSL $SERVER_SETUP_SITE/nginx/$site.conf -o $path
  sed -i "s/\${DOMAIN_NAME}/${DOMAIN_NAME}/g" $path
done

# Services
mkdir -p /opt/setup
services=(
  block_device
  letsencrypt_config
  openai
)
for service in "${services[@]}"; do
  path=/opt/setup/$service.sh
  curl -fsSL $SERVER_SETUP_SITE/scripts/$service.sh -o $path
  chmod +x $path
done
for service in "${services[@]}"; do
  curl -fsSL $SERVER_SETUP_SITE/systemd/$service.service -o /etc/systemd/system/$service.service
  systemctl enable $service
done

systemctl daemon-reload
