# Docker OJS dev

A docker container for Open Journal Systems for developing themes and plugins.

Creates an OJS installation, persists the OJS database and files and
opens OJS's plugins folder to the host. Allows you to download, modify or 
create OJS themes and plugins. PHPMyAdmin is installed too. 

Currently runs:

* Open Journal Systems 3.4.0 stable
* Alpine Linux 3.16, PHP 8.1, MariaDB 11.2, PHPMyAdmin 5.2.0

But older versions are easily configurable.

Meant for local development only. Largely based on 
[PKP's docker-ojs](https://github.com/pkp/docker-ojs).

Copyright 2022-24 Julien Dutant, GPL3 license.

## Basic usage

### Run OJS

Install [Docker](https://www.docker.com/). Clone this repository (e.g. 
download and unzip) and execute the following in a terminal at the root 
of the repository:

```bash
docker-compose up -d
```

The first run might take some time (downloading and creating container
images). If all goes well a local web server is set up with the 
following addresses:

* `https://localhost:8081` Open Journal Systems
* `https://localhost:8481` Open Journal Systems (SSL connection)
* `http://localhost:8082` PHPMyAdmin

(There is not much point in using the SSL port. If you do, your browser
will warn you that the site's certificate isn't trusted. Bypass the warning.)

Open a browser and navigate to `localhost:8081`. This will open the OJS
install page. You MUST use the following settings:

* Upload directory: `/var/www/files`
* Database driver: MySQLi
* host: `db`
* username: `ojs`
* password: `ojs`
* database name: `ojs`

Fill in the rest as you wish and install OJS. You can create a journal,
publish articles.

_Note_. As of OJS versions 3.3, 3.4, you need to have an active internet
connection when installing OJS in the Docker. 
See [below](#troubleshooting) for details.

To download plugins, you have to make the `/volumes/plugins` folder
of the repository writable by the docker-contained application. 
See below.

Once you are done, return to the
terminal and use:

```bash
docker-compose down
```

To stop the container. You can recreate the container with 
`docker-compose up -d`: the website is preserved (accounts, journals,
articles, files, plugins and their settings). Shut it again with 
`docker-compose down`. 

### Update

If you've updated this repo or the docker image definition, rebuild
your docker images with `docker-compose build`. 

### Cleanup

If you want to erase your user data and start with a fresh
install, use the cleanup script:

```bash
./tools/cleanup.sh
```

The script offers you the option to clean the site data (OJS config,
accounts, journals, articles etc.) and any custom OJS plugins
you've added or developed.

Make sure the container is down first (`docker-compose down`).

### PHPMyAdmin

Inspect the database with PHPMyAdmin: browse to `localhost:8082`.

### Folders

The `volumes` folder gives you access to several of the website folders:

* `volumes/logs/apache`: apache (server) logs
* `volumes/logs/mysql`: database log
* `volumes/private`: OJS's uploaded files (`/var/www/files/` in the 
	`app_ojs-dev` container)
* `volumes/public`: OJS's public folder (`/var/www/public/` in the 
	`app_ojs-dev` container)
* `volumes/plugins`: OJS's plugins folder. Initially contains only links 
	to the core plugins which you can't open from outside the container.
	Used to download plugins or develop your own (see below).
* `volumes/database`: the database files. Don't touch them; use 
	PHPMyAdmin instead.

You can also inspect and change OJS's config file:

* `volumes/config/config.inc.php`: OJS's configuration file

### Terminal

Docker runs the OJS server, database, PHPMyAdmin in isolated Linux 
systems ("containers"). You may want to run a terminal on those systems
to explore their files and folders. To do so you can either use
the Docker Desktop app (Containers > ojs-dev stack > app-ojs-dev > 
Actions > Open in Terminal for the OJS server) or run the following 
at the command line:

```bash
docker exec -it app_ojs-dev /bin/sh
```

The database server is `db_ojs-dev` and the PHPMyAdmin server is 
`PHPMyAdmin_ojs-dev`. If you have changed the default container names
 adapt accordingly.

The command line above assumes the container runs Alpine Linux. Others
may work with `/bin/bash` instead. If in doubt, 

### Installing plugins

#### From the web interface

Make the folder `volumes/plugins` writable by all:

```bash
chmod -R a+rwx plugins 
```

Browse to the application. You can now download and install
plugins. After installation, they are available outside 
of the container in `volumes/plugins`. You can modify
them for development.

You can also download or create your own plugins. Place them
within the `volumes/plugins` subfolders. 

### Tutorial

Suppose you want to [create a custom OJS 
theme](https://docs.pkp.sfu.ca/pkp-theming-guide/). Let's say you want
to modify PKP's [Classic](https://github.com/pkp/classic). 

First
make sure your container is down (`docker-compose down`). Download the
[Classic theme source code](https://github.com/pkp/classic) and 
place it in this repository at `volumes/plugins/themes/classic`. (You 
will probably )
Launch the OJS website with `docker-compose up -d`. Browse to 
`localhost:8081`. Install OJS and create a journal if needed. Enter
the journal apparence settings and the 'Classic' theme should now
be available. You can then modify the code 
in `volumes/plugins/themes/classic` and test the results in your 
browser.

### Details

Any plugin placed in the `volumes/plugins` subfolder will be accessible 
to OJS. Note that the plugins should be placed in subfolders by 
category:

* `volumes/plugins/importexport` for import-export plugins
* `volumes/plugins/themes` for theme plugins
* etc.

To install a plugin you only need to copy its folder here, OJS will
load it automatically. 

This Docker container uses symbolic links to provide the default OJS 
plugins. Fill free to delete them and replace them with your own versions
of the default OJS plugins. 

How this works: the OJS container (default name `app_ojs-dev`) contains
a copy of the default plugins (at `/var/www/html/plugins-backup`). 
When you run `docker-compose up`, the startup script scans your
`volume/plugins` folder and creates symbolic links to any plugin
present in `plugins-backup` but missing in your folder. Thus OJS finds
the default plugin at its expected place. If you remove the link and 

__Note__. If you remove a symbolic link for a *category* folder in 
order to install your custom plugin, you should restart the container
(or launch the script `/usr/local/bin/ojs-provide-core-plugins` within
the container). 

To illustrate, suppose you've launched the container and there's 
an automatically-generated `importexport` symbolic link in the 
`volumes/plugins` folder. You want to install a new import-export plugin,
so you delete the link, create a `importexport` folder instead, and 
place your plugin within it. However, your OJS container was still 
running! If you browse to OJS now, your plugin will
be visible, *but all the other import-export plugins will appear lost*. 
To fix this, simply restart the container (`docker-compose restart`). 
The startup script will then fill in your new `importexport` folder
with symbolic links to the other importexport folders. __Or better,
simply stop your container when you're installing a new plugin.__

## Customization

### Run older versions of OJS

OJS docker images are defined in `services/<OJS-version>`, where `<OJS-version>`
is the name of the desired version branch of the 
[PKP's official OJS repository](https://github.com/pkp/ojs). Each OJS version
provides one or more Docker images; one per PHP version. Database and PHPMyAdmin
images are provided separately.

If there are folders for your desired versions, enter them in `.env`, and
use `docker-compose build` to rebuild your images.

If there is no folder for your desired version, it is easy to adapt
the existing ones and create your own:

* `config.TEMPLATE.inc.php` is OJS's template config file for your version 
  (used by the cleanup script to reset your container data).
* for each php version you want to provide, `php<VERSION>` should contain 
  a Dockerfile for your image, and the files to be transferred to the 
  image, namely apache and PHP configuration files and OJS startup 
  scripts. 

### Advanced configuration

`volume/config/config.inc.php` contains OJS's configuration file.

The `.env` and `docker-compose.yml` contain most of the configuration:
container names, MySQL root password, username and password, ports, 
shared volumes. If you modify them you need to restart the container 
(`docker-compose restart`).

In `volumes/config` you can create some configuration files. You need
to uncomment the corresponding lines in `docker-compose.yml` and 
relauch the containers:

* `apache.htaccess`: a `.htaccess` file (`\var\www\html\.htaccess` within
  the container)
* `php.custom.ini`: a `php.custom.ini` file (`/etc/php7/php.custom.ini`
	within the container)
* `db.charset.conf`: a mysql charset conf file 
	(`/etc/mysql/conf.d/charset.cnf` within the container)

The `services/php<VERSION>` folder is used to create the OJS server. Its 
`root` subfolder is copied at the `/` within the container. 
In particular:

* `usr/local/bin/` contains scripts to run the server:
	- `ojs-start` is ran when you start the container. It itself runs
		`ojs-pre-start` which runs `ojs-provide-core-plugins` in turn.
	- `ojs-pre-start` sets up the apache server
	- `ojs-provide-core-plugins` ensures that `volumes/plugins` contains
		symbolic links for any missing core OJS plugins (links are to
		`volumes/plugins-backup` within the container)
	- other scripts are from 
		PKP's docker-ojs](https://github.com/pkp/docker-ojs)
* `etc/apache2/conf.d/ojs.conf` contains the apache configuration.

If you modify anything in `services/php74` you need to rebuild the
docker image used by the container: run `docker-compose build` at 
the root of the directory. Make sure the container is down first.

## Troubleshooting

### First OJS login requires an internet connection

Right after OJS is installed, you are sent to the login page. If you 
don't have an internet connection, you'll only get a blank page. The
apache log (`volumes/logs/apache/error.log`) displays the following PHP error:

```
[php:error] [pid 165] [client 192.168.65.1:64908] PHP Fatal error:  Uncaught GuzzleHttp\\Exception\\ConnectException: cURL error 6: Could not resolve host: pkp.sfu.ca (see https://curl.haxx.se/libcurl/c/libcurl-errors.html) for https://pkp.sfu.ca/ojs/xml/ojs-version.xml?id=B9557820-BC35-44F4-80A4-C43E135AC5A4&oai=http%3A%2F%2Flocalhost%3A8081%2Findex.php%2Findex%2Foai in /var/www/html/lib/pkp/lib/vendor/guzzlehttp/guzzle/src/Handler/CurlFactory.php:210\nStack trace:...  thrown in /var/www/html/lib/pkp/lib/vendor/guzzlehttp/guzzle/src/Handler/CurlFactory.php on line 210
```

OJS's installation script appears to need resources (namely, `guzzlehttp`) 
from PKP's official server and fails without them.

*Solution*. You need an active internet collection on your first login.

### OJS CLI Install

The CLI install script does not work at this stage.

## Contribute

PRs welcome. If you clone the repository for contributing, it's a
good idea to keep the main or contributing branch without OJS
installed, and a separate branch with OJS installed for testing
purposes. Just remember to shut down the container when you're
switching back to the main branch. 

## Credits

Largely based on 
[PKP's docker-ojs](https://github.com/pkp/docker-ojs), with some 
inspiration from
 [docker-compose-lamp](https://github.com/sprintcube/docker-compose-lamp).

