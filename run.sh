#!/bin/bash
set -e
# -e = Exit immediately if a command exits with a non-zero status

# Set as hardcode, it's easier
PROJECT_DIR=/home/kuba/3sky.io

# Cleanup public directory
# Always be sure what you delete
rm -rf $PROJECT_DIR/public

# Generate static
cd $PROJECT_DIR
hugo

# Copy directory
sudo cp -R $PROJECT_DIR/public /var/www/

# Change owner of file
sudo chown -R $(ps aux|grep nginx|grep -v grep| grep -v master| cut -d" " -f1). /var/www/public/

# Restart Nginx
sudo systemctl restart nginx.service
