#!/bin/bash -e

function usage {
  echo "Usage: $0 <name> | all"
  echo "Start or restart service in directory <name> with pm2"
}

. utils.sh

echo "Start service $1"
cd $1

ECOSYSTEM_EXAMPLE=ecosystem.example.json
ECOSYSTEM=ecosystem.config.json

if [[ -f $ECOSYSTEM ]]; then
  echo "Using ecosystem file $ECOSYSTEM without adjustments"
  pm2 reload $ECOSYSTEM || pm2 start $ECOSYSTEM
elif [[ -f $ECOSYSTEM_EXAMPLE ]]; then
  echo "Using and adjusting ecosystem file $ECOSYSTEM_EXAMPLE"

  # add or adjust service name
  SCRIPT="console.log(JSON.stringify(Object.assign(\
  JSON.parse(require('fs').readFileSync('$ECOSYSTEM_EXAMPLE')),{name:'$1'}),null,2))"

  node -e "$SCRIPT" > $ECOSYSTEM

  # reload or start
  pm2 reload $ECOSYSTEM || pm2 start $ECOSYSTEM
else
  NAME=$(basename $1)
  echo "Assuming pm2 process name to be $NAME"

  pm2 reload $NAME || pm2 start $NAME
fi

# show status
pm2 list -m | awk "\$1==\"+---\" {P=\$2==\"$1\"} P {print}"
