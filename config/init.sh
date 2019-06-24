#!/bin/bash

# Install Drupal.
cd $LANDO_MOUNT
if [ -d 'web' ]; then
    echo "Web folder already exists. No git clone executed."
    FIRST_RUN=0
else
    # Do a git checkout of the current D8 core.
    echo "Cloning drupal core."
    git clone --depth 1 https://git.drupal.org/project/drupal.git web
    FIRST_RUN=1
fi

echo "Composer installing drupal core."
cd /app/web
composer install

if [ $FIRST_RUN ]; then
    # Upgrade PHPUnit to work with PHP 7, add drush, console, selenium
    composer require --update-with-dependencies "phpunit/phpunit ^6.0" "drush/drush" "drupal/console" "joomla-projects/selenium-server-standalone"
fi

# Create file dirs.
echo "Creating dirs and symlinks."
cd /app
mkdir -p -m 777 /app/web/sites/default/files/phpunit
mkdir -p -m 777 /app/web/sites/simpletest
mkdir -p -m 777 /app/files/private
mkdir -p -m 777 /app/files/tmp
mkdir -p -m 777 /app/files/sync

# Copy the settings and symlink the file dirs.
if [ ! -e "/app/web/sites/default/settings.php" ]; then
    cp /app/config/sites.default.settings.php /app/web/sites/default/settings.php
fi
if [ ! -L "/app/files/public" ]; then
    ln -s /app/web/sites/default/files /app/files/public
fi
if [ ! -L "files/simpletest" ]; then
    ln -s /app/web/sites/simpletest /app/files/simpletest
fi

if [ $FIRST_RUN ]; then
    echo "Installing default site."
    cd /app/web
    drush site-install -y
    cd /app/
fi

if [ ! -f /app/web/.gitignore ]; then
    # Ignore changed core files
    echo "composer.json
composer.lock
vendor
sites/default/settings.php
sites/default/files
sites/simpletest
" > /app/web/.gitignore
fi

# Create phpunit.xml and configure.
if [ ! -f /app/web/core/phpunit.xml ]; then
    echo 'Creating phpunit.xml.'
    cd /app/web/core
    cp phpunit.xml.dist phpunit.xml
    sed -i 's/SIMPLETEST_DB" value=""/SIMPLETEST_DB" value="sqlite:\/\/localhost\/\/app\/web\/sites\/default\/files\/test.sqlite"/' phpunit.xml
    sed -i 's/SIMPLETEST_BASE_URL" value=""/SIMPLETEST_BASE_URL" value="http:\/\/\'$LANDO_APP_NAME'.'$LANDO_DOMAIN'"/' phpunit.xml
    sed -i 's/BROWSERTEST_OUTPUT_DIRECTORY" value=""/BROWSERTEST_OUTPUT_DIRECTORY" value="\/app\/web\/sites\/default\/files\/phpunit"/' phpunit.xml
    sed -i 's/beStrictAboutOutputDuringTests="true"/beStrictAboutOutputDuringTests="false" verbose="true"/' phpunit.xml
    sed -i 's/<\/phpunit>/<logging><log type="testdox-text" target="\/app\/web\/sites\/default\/files\/testdox.txt"\/><\/logging><\/phpunit>/' phpunit.xml
fi
