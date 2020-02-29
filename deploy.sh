#!/bin/bash
set -e
# -e = Exit immediately if a command exits with a non-zero status

# Cleanup public directory
rm -rf 3sky/blog-src/public

# get hugo version
hugo version

# Generate static
ls -lR
cd blog-src
hugo

# Clone page repo
ls -lR
git clone https://github.com/3sky/3sky.github.io 

# Copy content
cp -R public/* 3sky.github.io

ls -lR 3sky.github.io
# Push to repo
# cd 3sky.github.io
# git push