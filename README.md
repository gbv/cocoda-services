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

Run `./scripts.import.sh jskos-server concordances`.
