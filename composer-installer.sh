#!/bin/sh
# Composer Installer Script
# Securely downloads and installs Composer globally on Linux
# Usage: ./install-composer.sh [version]
# Example: ./install-composer.sh 2.7.2

set -e

VERSION=${1:-latest}

echo ">> Checking PHP installation..."

if ! command -v php >/dev/null 2>&1; then
    echo ">> PHP is not installed. Installing latest PHP..."

    if command -v apt >/dev/null 2>&1; then
        sudo apt update
        sudo apt install -y php php-cli php-mbstring unzip curl

    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y php php-cli php-mbstring unzip curl

    elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y php php-cli php-mbstring unzip curl

    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm php unzip curl

    elif command -v zypper >/dev/null 2>&1; then
        sudo zypper install -y php php-cli php-mbstring unzip curl

    else
        echo "ERROR: Unsupported package manager."
        exit 1
    fi
fi

echo ">> PHP version:"
php -v

echo ">> Fetching expected checksum..."
EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"

echo ">> Downloading installer..."
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"

echo ">> Verifying installer..."
ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
    >&2 echo 'ERROR: Invalid installer checksum'
    rm composer-setup.php
    exit 1
fi

echo ">> Installing Composer ($VERSION)..."

if [ "$VERSION" = "latest" ]; then
    php composer-setup.php --quiet
else
    php composer-setup.php --quiet --version="$VERSION"
fi

rm composer-setup.php

echo ">> Moving Composer to /usr/local/bin..."
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer

echo ">> Installation complete."
composer --version
