# cocoda backend services

This home directory of user `cocoda` is used to host backend services.

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

### jskos-server: Adding Concept Schemes or Concepts

**Note:** This is here for documentation purposes and will be improved and simplified soon!

1. Update kos-registry if necessary. 

1. Update jskos-data if necessary.

1. Navigate to jskos-server's import folder: `cd ~/jskos-server/imports/`

1. Edit the file `assemble-schemes.sh` to include the new concept scheme(s) via URI(s).

1. Run the file: `./assemble-schemes.sh`.

1. For concepts: Add the file with path for the concepts to `concepts.txt`.

1. Return to the parent directory: `cd ..` (or `cd ~/jskos-server/` if you're already somewhere else).

1. Import schemes: `npm run import-batch -- schemes imports/schemes.txt`.

1. For concepts: `npm run import-batch -- concepts imports/concepts.txt`.
