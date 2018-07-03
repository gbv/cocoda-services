#!/bin/bash -e

function usage {
  echo "Usage: $0 <name> | all"
  echo "Start or restart service in directory <name> with pm2"
}

. utils.sh

echo "Start service $1"
cd $1

if [[ -f server.js ]]; then
  pm2 describe $1 > /dev/null
RUNNING=$?

if [ "${RUNNING}" -ne 0 ]; then
  # FIXME: restart if already running, start otherwise
  pm2 startOrRestart server.js --name $1
else
  error "Don't know how to start service $1"
fi
