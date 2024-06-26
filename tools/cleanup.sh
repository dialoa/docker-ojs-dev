#!/bin/sh

if [ ! -f ".env" ]; then
	echo "This script must be launched from the repo's root";
	echo "   sh tools/cleanup.sh";
	exit
fi

# get OJSVERSION from .env
source .env

CONFIG_FILE_TEMPLATE=services/${OJSVERSION}/config.TEMPLATE.inc.php
CONFIG=volumes/config
CONFIG_FILE=${CONFIG}/config.inc.php
LOGS=volumes/logs
APACHE_LOGS=${LOGS}/apache
MYSQL_LOGS=${LOGS}/mysql
DATABASE=volumes/database
PRIVATE=volumes/private
PUBLIC=volumes/public
PLUGINS=volumes/plugins

read -p "WARNING: Do you want to erase the site's user data \
(config, accounts, journals, article files, logs)? (y/N) " ans

case $ans in 
	[yY] ) rm -rf ${CONFIG} && mkdir -p ${CONFIG} 
		cp ${CONFIG_FILE_TEMPLATE} ${CONFIG_FILE}
		rm -rf ${APACHE_LOGS} ${MYSQL_LOGS}
		mkdir -p ${APACHE_LOGS} ${MYSQL_LOGS}
		rm -rf ${DATABASE} && mkdir -p ${DATABASE}
		rm -rf ${PRIVATE} && mkdir -p ${PRIVATE}
		rm -rf ${PUBLIC} && mkdir -p ${PUBLIC}
		echo "Site data erased."
		break;;
	* ) echo "Operation cancelled.";;
esac

read -p "WARNING: Do you want to erase your custom plugins? (y/N) " ans

case $ans in 
	[yY] ) rm -rf ${PLUGINS} && mkdir -p ${PLUGINS}
		echo "Plugins erased."
		break;;
	* ) echo "Operation cancelled.";;
esac
