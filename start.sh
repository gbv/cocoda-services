#!/bin/bash -e

function usage {
  echo "Usage: $0 <name> | all"
  echo "Start or restart service in directory <name> with pm2"
}

. utils.sh

echo "Start service $1"
cd $1

ECOSYSTEM=ecosystem.config.json
[[ -f $ECOSYSTEM ]] || error "Missing file $ECOSYSTEM" 

NAME=`node -e "console.log(JSON.parse(require('fs').readFileSync('$ECOSYSTEM')).name)"`
[[ "$NAME" = $1 ]] || error "Wrong service name in $ECOSYSTEM"

pm2 reload $ECOSYSTEM || pm2 start $ECOSYSTEM
