#!/bin/bash
set -e
# -e = Exit immediately if a command exits with a non-zero status

# get hugo version
hugo version

# Cleanup public directory
rm -rf public

# Generate static
hugo

# Clone page repo
git clone https://github.com/3sky/3sky.github.io 

# Copy content
cp -R public/* 3sky.github.io

# Push to repo
cd 3sky.github.io

# Push tp repo with token
git config --global user.email "3sky@protonmail.com"
git config --global user.name "3sky"

git add -A
git commit --message "Travis build: $TRAVIS_BUILD_NUMBER"

git remote set-url origin https://3sky:${GH_TOKEN}@github.com/3sky/3sky.github.io.git >/dev/null 2>&1
git push --quiet --set-upstream origin master
