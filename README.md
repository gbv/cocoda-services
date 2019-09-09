# cocoda backend services

This home directory of user `cocoda` is used to host backend services used in
[project coli-conc](https://coli-conc.gbv.de/).

## Overview

Services are listed in `services.txt` with their git URL to clone/pull from.
Each service repository is expected to include a file `ecosystem.config.json`
like this (see [pm2 documentation] for details):

```json
{
  "name": "service-name",
  "script": "./server.js"
}
```

[pm2 documentation]: http://pm2.keymetrics.io/docs/usage/application-declaration/

Each services can be installed into a directory with script `install.sh`.
The directory name is also used as service name. The install script also
calls `init.sh` to initialize dependencies (and build the service, if needed).

To start or restart a service, call `start.sh`.

Use `update.sh` to update and restart services (unless updating is broken).

## Requirements

* [pm2](http://pm2.keymetrics.io/)

* [realpath](http://man7.org/linux/man-pages/man1/realpath.1.html)

## Installation

Clone this repository:

```bash
cd /srv/cocoda  # or wherever to put services under
git init
git remote add origin https://github.com/gbv/cocoda-services.git
git pull origin master
```

Install all services listed in `services.txt`:

```bash
./install.sh all
```

## Service-Specific Instructions

[jskos-server]: https://github.com/gbv/jskos-server

### [jskos-server]: Adding Concept Schemes

1. Add URI of concept scheme to `scripts/jskos-server/scheme-uris.txt`.

1. Run `./scripts/import.sh jskos-server schemes`.

Note: The file `scripts/jskos-server/schemes.ndjson` is generated automatically from `kos-registry`.

### [jskos-server]: Adding Concepts

1. Add file path to concepts file to `scripts/jskos-server/concepts.txt`.

1. Run `./scripts/import.sh jskos-server concepts`.

### [jskos-server]: Reimport Concordances

Run `./scripts.import.sh jskos-server concordances`. This happens every night via the cron job so it should only be necessary if you want to add a new concordance during the day.

## Cron Jobs
Cron jobs currently need to be configurated manually.

```bash
# daily reimport of concordances in jskos-server
10 01 * * * ./scripts/import.sh jskos-server concordances > /srv/cocoda/logs/jskos-server_concordances.log

# hourly backup of jskos-server + jskos-server-kenom user mappings
00 * * * * /srv/cocoda/scripts/backup.sh >> /srv/cocoda/backup.log

# kenom mapping statistics
20 * * * * cd /srv/cocoda/kenom-mappings; make stats

# nightly import of ccmapper recommendations (note: add FTP credentials!)
00 05 * * * FTP_USER=<ftpuser> FTP_PASS=<ftppass> FTP_HOST=<ftphost> FILE=generated SERVER_PATH=/srv/cocoda/jskos-server-ccmapper SERVER_RESET=yes /srv/cocoda/scripts/import.sh jskos-server-ccmapper mappings > /srv/cocoda/logs/jskos-server-ccmapper_mappings.log
```
