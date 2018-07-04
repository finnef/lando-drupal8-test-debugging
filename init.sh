#!/bin/bash

# Install Drupal.
cd $LANDO_MOUNT
if [ -d 'web' ]; then
    echo "Web folder already exists. No git clone executed."
else
    # Do a git checkout of the current D8 core.
    echo "Cloning drupal core."
    git clone --depth 1 https://git.drupal.org/project/drupal.git web
    echo "Composer installing drupal core."
    cd web
    composer install

    # Upgrade PHPUnit to work with PHP 7, add drush.
    composer require "phpunit/phpunit ^6.0" "drush/drush"

    echo "Installing default site."
    # Create file dirs.
    cd $LANDO_MOUNT
    mkdir -p -m 777 web/sites/default/files
    mkdir -p -m 777 files/private
    mkdir -p -m 777 files/tmp

    # Symlink the settings and public file dir.
    if [ ! -L "$LANDO_MOUNT/web/sites/default/settings.php" ]; then
        ln -s $LANDO_MOUNT/sites.default.settings.php $LANDO_MOUNT/web/sites/default/settings.php
    fi
    if [ ! -L "$LANDO_MOUNT/files/public" ]; then
        ln -s $LANDO_APP_ROOT_BIND/web/sites/default/files $LANDO_MOUNT/files/public
    fi

    drush site-install
fi

if [ ! -f /app/web/.gitignore ]; then
    # Ignore changed core files
    echo "composer.json
composer.lock
vendor
sites/default/settings.php
sites/default/files
sites/simpletest
" > .gitignore
fi

# Create phpunit.xml and configure.
if [ ! -f /app/web/core/phpunit.xml ]; then
    echo 'Creating phpunit.xml.'
    cd app/web/core
    cp phpunit.xml.dist phpunit.xml
    sed -i 's/SIMPLETEST_DB" value="/SIMPLETEST_DB" value="sqlite:\/\/localhost\/\/app\/web\/sites\/default\/files\/test.sqlite/g' phpunit.xml
    sed -i 's/SIMPLETEST_BASE_URL" value="/SIMPLETEST_BASE_URL" value="http:\/\/\'$LANDO_APP_NAME'.'$LANDO_DOMAIN'/g' phpunit.xml
fi
