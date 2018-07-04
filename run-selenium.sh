#!/bin/bash

# Prepare PATH for Chrome web driver.
case "$(uname -s)" in
   Darwin)
     echo 'detected Mac OS X'
     DRIVER_PATH=mac
     ;;
   Linux|GNU*|*BSD)
     echo 'detected Linux'
     DRIVER_PATH=linux
     ;;
   CYGWIN*|MINGW32*|MSYS*)
     echo 'detected Windows'
     DRIVER_PATH=windows
     ;;
esac
export PATH=`pwd`/web/vendor/joomla-projects/selenium-server-standalone/bin/webdrivers/chrome/$DRIVER_PATH:$PATH

# Launch Selenium.
`pwd`/web/vendor/bin/selenium-server-standalone
