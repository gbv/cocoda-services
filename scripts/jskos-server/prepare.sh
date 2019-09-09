#!/bin/bash

DIR=$(dirname "$0")
KOS="$DIR/../../kos-registry/all.ndjson"
SOURCE_FILE="$DIR/scheme-uris.txt"
TARGET_FILE="$DIR/schemes.ndjson"

[ -f $TARGET_FILE ] && rm $TARGET_FILE
while read uri; do
  cat $KOS | grep "$uri" >> $TARGET_FILE
done <$SOURCE_FILE
