#!/bin/bash

DIR=$(dirname "$(realpath -s "$0")")
KOS="$DIR/../../bartoc.org/data/dumps/latest.ndjson"
SOURCE_FILE="$DIR/scheme-uris.txt"
TARGET_FILE="$DIR/schemes.ndjson"

[ -f $TARGET_FILE ] && rm $TARGET_FILE
while read uri; do
  jq -c 'select(.uri=="'"$uri"'")' $KOS >> $TARGET_FILE
done <$SOURCE_FILE
