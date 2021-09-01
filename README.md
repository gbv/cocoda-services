# cocoda backend services

> backend services used in [project coli-conc](https://coli-conc.gbv.de/)

This repository contains the home directory of user `cocoda` to host services
listed in `services.txt` with their git URL to clone/pull from.

Each service repository is expected to include a file `ecosystem.config.json`
like this (see [pm2 documentation] for details):

```json
{
  "name": "service-name",
  "script": "./server.js"
}
```

[pm2 documentation]: http://pm2.keymetrics.io/docs/usage/application-declaration/

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Install](#install)
- [Usage](#usage)
- [Service-Specific Instructions](#service-specific-instructions)
  - [[jskos-server]: Adding Concept Schemes](#jskos-server-adding-concept-schemes)
  - [[jskos-server]: Adding Concepts](#jskos-server-adding-concepts)
  - [[jskos-server]: Concordances](#jskos-server-concordances)
- [Cron Jobs](#cron-jobs)
- [Automatic Deployment](#automatic-deployment)
  - [Update via push event on specific branch](#update-via-push-event-on-specific-branch)
  - [Update via release event](#update-via-release-event)
- [Contributing](#contributing)
- [License](#license)

## Install

Requires [pm2](http://pm2.keymetrics.io/) and [realpath](http://man7.org/linux/man-pages/man1/realpath.1.html).

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

Enable logfile rotation to avoid full disk:

```bash
pm2 install pm2-logrotate
```

## Usage

Each services can be installed into a directory with script `install.sh`.
The directory name is also used as service name. The install script also
calls `init.sh` to initialize dependencies (and build the service, if needed).

To start or restart a service, call `start.sh`.

Use `update.sh` to update and restart services (unless updating is broken).

## Service-Specific Instructions

[jskos-server]: https://github.com/gbv/jskos-server

Note: Instructions relating to jskos-server can be used for jskos-server-dev as well. jskos-server-dev is available as a registry in the [Cocoda dev instance](https://coli-conc.gbv.de/cocoda/dev/), so it can be used as a playground for importing newly converted vocabularies.

### [jskos-server]: Adding Concept Schemes

Most of the concept scheme data is taken from the latest BARTOC dump under `/srv/cocoda/bartoc.org/data/dumps/latest.ndjson`. To add a new concept scheme from BARTOC:

1. Add the BARTOC URI of the concept scheme to `scripts/jskos-server/scheme-uris.txt`.

2. Run `./scripts/import.sh jskos-server schemes`.

Note: The file `scripts/jskos-server/schemes.ndjson` is generated automatically from `kos-registry`.

In the long term, concept schemes will be loaded from BARTOC directly.

If you need to add a custom concept scheme that is not (yet) in BARTOC, add the path to the `.json` or `.ndjson` file to `scripts/jskos-server/schemes.txt`.

### [jskos-server]: Adding Concepts

The source of truth for concept data is in [jskos-data](https://github.com/gbv/jskos-data). That repository is initialized under `/srv/cocoda/jskos-data/` and will need to be updated manually. To add new concept data to jskos-server:

1. Add file path to concepts file to `scripts/jskos-server/concepts.txt`.

1. Run `./scripts/import.sh jskos-server concepts`. This will reimport ALL the concepts for all concept schemes, so it will take a while.

<!-- TODO: How to do a partial import? -->

### [jskos-server]: Concordances

Originally, concordances were imported similarly to concept schemes and concepts above. However, as of 2021, the source of truth for concordances and mappings will be the jskos-server database that is hosted under https://coli-conc.gbv.de/api/. Imports of new mappings and concordances need to be performed manually for that instance:

```bash
# go into the instance's folder
cd /srv/cocoda/jskos-server
# import concordance metadata (note that if the metadata contains valid distribution data for the mappings, the mappings will also be imported in this step!)
npm run import -- concordances /path/or/url/to/concordance/data.json
# import mappings (if necessary)
npm run import -- mappings /path/or/url/to/mappings.ndjson
# in case mappings from a certain concordance need to be deleted first (note that only the mappings, not the metadata, is removed, and that it will ask for confirmation; to delete the metadata as well, remove the `-c` from the command)
npm run reset -- -c http://coli-conc.gbv.de/concordances/my_concordance
```

Also refer to [jskos-server]'s data import section in the README [here](https://github.com/gbv/jskos-server#data-import).

## Cron Jobs
Cron jobs currently need to be configurated manually.

```bash
# hourly backup of jskos-server + jskos-server-kenom user mappings
00 * * * * /srv/cocoda/scripts/backup.sh >> /srv/cocoda/logs/backup.log

# kenom mapping statistics
20 * * * * cd /srv/cocoda/kenom-mappings; make stats

# nightly import of ccmapper recommendations (note: add FTP credentials!)
00 05 * * * FTP_USER=<ftpuser> FTP_PASS=<ftppass> FTP_HOST=<ftphost> FILE=generated SERVER_PATH=/srv/cocoda/jskos-server-ccmapper SERVER_RESET=yes /srv/cocoda/scripts/import.sh jskos-server-ccmapper mappings > /srv/cocoda/logs/jskos-server-ccmapper_mappings.log
```

## Automatic Deployment
We are using [github-webhook-handler](https://github.com/gbv/github-webhook-handler) to handle updates from GitHub via webhooks. The webhooks and respective actions are configured in `/srv/cocoda/github-webhook-handler/config.json` (not included in the repository). Please refer to the documentation and the configuration file on how to configure the webhooks. The file looks like this:

```json
{
  "port": 2999,
  "secret": "a secret",
  "webhooks": [

  ]
}
```

In `webhooks`, all the specific webhooks are configured. There are two main ways to use this for deployment:

### Update via push event on specific branch
This is the easiest way to update a service. Example webhook configuration:

```json
{
  "repository": "gbv/login-server",
  "path": "/srv/cocoda/",
  "command": "./update.sh login-server",
  "ref": "refs/heads/master",
  "event": "push"
}
```

### Update via release event
This is more complicated because it requires downloading and unzipping the release. Example webhook configuration for the Cocoda release instance:

```json
{
  "repository": "gbv/cocoda",
  "path": "/srv/cocoda/cocoda/",
  "command": "wget $DOWNLOAD -O $VERSION.zip; unzip $VERSION.zip -d $VERSION-temp; mv $VERSION-temp/cocoda/ $VERSION; rm $VERSION.zip; rm -r $VERSION-temp; cp app/cocoda.json $VERSION/cocoda.json; rm app; ln -sf $VERSION app; ./updateBuilds.sh",
  "event": "release",
  "action": "published",
  "env": {
    "body.release.assets[0].browser_download_url": "DOWNLOAD",
    "body.release.tag_name": "VERSION"
  }
}
```

After editing `config.json`, the service needs to be restarted: `pm2 restart github-webhook-handler`

In both cases, a webhook has to be configured in GitHub. Go to Settings -> Webhooks and add a new webhook:

- Payload URL: `https://coli-conc.gbv.de/github-webhook/` (always)
- Content type: `application/json` (always)
- Secret: refer to the configuration file on the server
- SSL verification: enabled
- Which events: either `push` or select and check `Releases`

## Contributing

See <https://github.com/gbv/cocoda-services/>.

The script `code-analysis.sh` can be used for static code analysis as quality control.

## License

Usage not restricted by copyright (Unlicense).
