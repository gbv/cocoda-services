# cocoda backend services (deprecated)

**Replaced by https://github.com/gbv/coli-conc-server**

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

## Table of Contents <!-- omit in toc -->

- [Install](#install)
- [Usage](#usage)
- [Service-Specific Instructions](#service-specific-instructions)
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
[jskos-data]: https://github.com/gbv/jskos-data
[BARTOC]: https://bartoc.org

Note: Instructions relating to jskos-server can be used for jskos-server-dev as well. jskos-server-dev is available as a registry in the [Cocoda dev instance](https://coli-conc.gbv.de/cocoda/dev/), so it can be used as a playground for importing newly converted vocabularies.

### [jskos-server]: Adding Vocabularies and Concepts <!-- omit in toc -->

Adding vocabularies and their concepts to one of our jskos-server instances relies on the `import-vocabularies.sh` script and the `vocabularies.txt` file.

1. Add the new vocabulary to [BARTOC]. Copy its BARTOC URI (**not** the browser URL; BARTOC URIs are http only).
2. Add a new entry in `vocabularies.txt`. The format is described there. If you have a vocabulary's concept data available in [jskos-data] as well, you can add the file's path there too.
    - Note: You should do this locally and push to GitHub or on GitHub directly. Then run `git pull` in the cocoda-services directory (e.g. `/srv/cocoda/`).
3. Run `./import-vocabularies.sh -g "<BARTOC URI>"`. This will import the vocabulary metadata as well as its concepts if available. If you need to reset the concepts before importing, add the `-r` flag. If you need to force the concept import without a prior reset, add the `-f` flag.
4. If a vocabulary's concept should be served via one of our [jskos-server] instances, add an appropriate API entry to its [BARTOC] entry. For the main instance, URL should be `https://coli-conc.gbv.de/api/` and API type should be `JSKOS API`. If the vocabulary should appear in Cocoda, add `http://bartoc.org/en/node/18926` to "Listed in" in [BARTOC].

After these steps, a vocabulary should be browsable in [BARTOC] and (if configured) in Cocoda after reloading the page.

In some cases, it might be required to reimport all vocabularies at once. In this case, you can run `./import-vocabularies.sh -r`. **Use with caution and check carefully!**

### [jskos-server]: Concordances <!-- omit in toc -->

Originally, concordances were imported similarly to vocabularies and concepts above. However, as of 2021, the source of truth for concordances and mappings will be the jskos-server database that is hosted under https://coli-conc.gbv.de/api/. Imports of new mappings and concordances need to be performed manually for that instance:

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
00 05 * * * FTP_USER=<ftpuser> FTP_PASS=<ftppass> FTP_HOST=<ftphost> FILE=generated SERVER_PATH=/srv/cocoda/jskos-server-ccmapper SERVER_RESET=yes /srv/cocoda/scripts/jskos-server-ccmapper/import.sh  mappings > /srv/cocoda/logs/jskos-server-ccmapper_mappings.log

# nightly dump of BARTOC.org
00 04 * * * cd /srv/cocoda/bartoc.org; npm run dump update
10 04 * * * cd jskos-server-bartoc-dev/; npm run import schemes ../bartoc.org/data/dumps/latest.ndjson
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
