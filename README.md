# cocoda backend services

This home directory of user `cocoda` is used to host backend services.

## Overview

Services are listed in `services.txt` with their git URL to clone/pull from.

Each services can be installed into a directory with script `install.sh`.
The directory name is also used as service name. The install script also
calls `init.sh` to initialize dependencies (and build the service, if needed).

To start or restart a service, call `start.sh`.

Use `update.sh` to update and restart services (unless updating is broken).

## Requirements

* git
* bash
* [pm2](http://pm2.keymetrics.io/)
* nodejs (required by pm2 anyway) 

## Installation

Clone this repository:

```bash
cd /srv/cocoda  # or wherever to put services under
git remote add origin https://github.com/gbv/cocoda-services.git 
git pull origin master
```

Install all services listed in `services.txt`:

```bash
./install.sh all
```

