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

    # Upgrade PHPUnit to work with PHP 7, add drush and selenium
    composer require --update-with-dependencies "phpunit/phpunit ^6.0" "drush/drush" "joomla-projects/selenium-server-standalone"

    echo "Installing default site."
    # Create file dirs.
    cd $LANDO_MOUNT
    mkdir -p -m 777 web/sites/default/files/phpunit
    mkdir -p -m 777 web/sites/simpletest
    mkdir -p -m 777 files/private
    mkdir -p -m 777 files/tmp
    mkdir -p -m 777 files/sync

    # Symlink the settings and public file dir.
    if [ ! -L "$LANDO_MOUNT/web/sites/default/settings.php" ]; then
        ln -s $LANDO_MOUNT/config/sites.default.settings.php $LANDO_MOUNT/web/sites/default/settings.php
    fi
    if [ ! -L "$LANDO_MOUNT/files/public" ]; then
        ln -s $LANDO_APP_ROOT_BIND/web/sites/default/files $LANDO_MOUNT/files/public
    fi
    if [ ! -L "$LANDO_MOUNT/files/simpletest" ]; then
        ln -s $LANDO_APP_ROOT_BIND/web/sites/simpletest $LANDO_MOUNT/files/simpletest
    fi

    cd web
    drush site-install
fi

if [ ! -f $LANDO_MOUNT/web/.gitignore ]; then
    # Ignore changed core files
    echo "composer.json
composer.lock
vendor
sites/default/settings.php
sites/default/files
sites/simpletest
" > $LANDO_MOUNT/web/.gitignore
fi

# Create phpunit.xml and configure.
if [ ! -f $LANDO_MOUNT/web/core/phpunit.xml ]; then
    echo 'Creating phpunit.xml.'
    cd $LANDO_MOUNT/web/core
    cp phpunit.xml.dist phpunit.xml
    sed -i 's/SIMPLETEST_DB" value=""/SIMPLETEST_DB" value="sqlite:\/\/localhost\/\'$LANDO_MOUNT'\/web\/sites\/default\/files\/test.sqlite"/' phpunit.xml
    sed -i 's/SIMPLETEST_BASE_URL" value=""/SIMPLETEST_BASE_URL" value="http:\/\/\'$LANDO_APP_NAME'.'$LANDO_DOMAIN'"/' phpunit.xml
    sed -i 's/BROWSERTEST_OUTPUT_DIRECTORY" value=""/BROWSERTEST_OUTPUT_DIRECTORY" value="\'$LANDO_MOUNT'\/web\/sites\/default\/files\/phpunit"/' phpunit.xml
    sed -i 's/beStrictAboutOutputDuringTests="true"/beStrictAboutOutputDuringTests="false" verbose="true" printerClass="\Drupal\Tests\Listeners\HtmlOutputPrinter"/' phpunit.xml
    sed -i 's/<\/phpunit>/<logging><log type="testdox-text" target="\'$LANDO_MOUNT'\/web\/sites\/default\/files\/testdox.txt"\/><\/logging><\/phpunit>/' phpunit.xml
fi
