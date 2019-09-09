#!/bin/bash

if [ -z $1 ]; then
  echo "Missing parameter <name> for target service."
  echo "Usage: $0 <name> [<type>]"
  echo "Run import for a service."
  echo "<type> can be one of schemes, concepts, concordances, mappings."
  exit 1
fi

DIR=$(dirname "$(realpath -s "$0")")
IMPORT_DIR="$DIR/$1/"
SERVICE_DIR="$DIR/../$1/"
TYPE=$2

echo "Starting import for $1..."
echo

# 1. If a prepare script exists in IMPORT_DIR, run that.
if [ -f "$IMPORT_DIR/prepare.sh" ]; then
  echo "Running prepare script for $1..."
  $IMPORT_DIR/prepare.sh $TYPE
  echo
fi

# 2. If an import script exists in IMPORT_DIR, run that, else run batch imports for different item types.
if [ -f "$IMPORT_DIR/import.sh" ]; then
  echo "Running import script for $1..."
  $IMPORT_DIR/import.sh $TYPE
  echo
else
  cd $SERVICE_DIR
  if [ ! -z "$TYPE" ]; then
    echo "Batch importing $TYPE..."
    npm run import-batch -- $TYPE $IMPORT_DIR/$TYPE.txt
  else
    TYPES=( "schemes" "concepts" "concordances" "mappings" )
    for TYPE in "${TYPES[@]}"
    do
      echo "Batch importing $TYPE..."
      npm run import-batch -- $TYPE $IMPORT_DIR/$TYPE.txt
    done
  fi
  echo
fi
