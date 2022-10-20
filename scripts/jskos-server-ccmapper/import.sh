#!/bin/sh

if [ $1 != "mappings" ]; then
  echo "Error: Only mappings are supported by this instance."
  exit 1
fi

# Required environment variables:
# - FTP_USER      username for FTP server
# - FTP_PASS      password for FTP server
# - FTP_HOST      FTP host
# - FILE          completed | generated | inprogress
# - TEMP_PATH     path where temporary files will be saved (no trailing slash)
# - SERVER_PATH   path where the jskos-server instance resides (no trailing slash)
# - SERVER_RESET  if it contains anything, the server will reset the mappings collection

# Set TEMP_PATH to ./ if empty
if [ -z "$TEMP_PATH" ]; then
  TEMP_PATH=/tmp
fi

# Exit if SERVER_PATH is empty
if [ -z "$SERVER_PATH" ]; then
  echo "Error: Please provide enviroment variable SERVER_PATH."
  exit 1
fi
# Exit if jskos-server import script could not be found
if [ ! -f $SERVER_PATH/bin/import.js ]; then
  echo "Error: Please check if SERVER_PATH is correct (import script not found)."
  exit 1
fi

echo "FILE: $FILE"
echo "TEMP_PATH: $TEMP_PATH"
echo "SERVER_PATH: $SERVER_PATH"
echo "If any errors occur, please consult the comments at the top of this script."

# Download newest file
echo "- Downloading newest file..."
wget -q ftp://$FTP_USER:$FTP_PASS@$FTP_HOST/prod/$FILE.json.gz -O $TEMP_PATH/$FILE.json.gz

# Check whether download succeeded
if [ $? -eq 0 ]; then
  echo "- Download succeeded."
else
  echo "Error: Download failed, exiting."
  rm $TEMP_PATH/$FILE.json.gz
  exit 1
fi

# Unzip
echo "- Unzipping file..."
gzip -df $TEMP_PATH/$FILE.json.gz

# Check whether unzip succeeded
if [ $? -eq 0 ]; then
  echo "- Unzipped: $(du -h $TEMP_PATH/$FILE.json)."
else
  echo "Error: Unzip failed, exiting."
  rm $TEMP_PATH/$FILE.json.gz
  exit 1
fi

echo "- Adjusting JSON file..."
jq '[.[] | .["mappingRelevance"] = ((._score | tonumber + 1) | log10) / 5.6 | del(._score)]' $TEMP_PATH/$FILE.json > $TEMP_PATH/$FILE.adjusted.json

# Run jskos-server import script
echo "- Running jskos-server import script..."
if [ ! -z "$SERVER_RESET" ]; then
  echo "  - Resetting server..."
  yes | $SERVER_PATH/bin/reset.js -t mappings
  $SERVER_PATH/bin/import.js --indexes mappings
fi
echo "  - Importing data..."
$SERVER_PATH/bin/import.js mappings $TEMP_PATH/$FILE.adjusted.json

# Delete files
echo "- Deleting files..."
for file in $TEMP_PATH/$FILE.*; do
  if [ -f $file ]; then
    rm $file
  fi
done
