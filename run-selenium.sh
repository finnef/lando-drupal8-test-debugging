#!/bin/bash

# Prepare PATH for Chrome web driver.
case "$(uname -s)" in
   Darwin)
     DRIVER_PATH=mac
     ;;
   Linux|GNU*|*BSD)
     DRIVER_PATH=mac
     ;;
   CYGWIN*|MINGW32*|MSYS*)
     DRIVER_PATH=windows
     ;;
esac
export PATH=`pwd`/web/vendor/joomla-projects/selenium-server-standalone/bin/webdrivers/chrome/$DRIVER_PATH:$PATH

# Launch Selenium.
`pwd`/web/vendor/bin/selenium-server-standalone
