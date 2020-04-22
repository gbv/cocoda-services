#!/bin/bash -e

repo=/srv/cocoda/mongobackup
/usr/bin/mongodump --quiet --db jskos-server-fso --collection mappings --query '{ uri: { $exists: true }, partOf: { $exists: false } }' --out $repo
/usr/bin/mongodump --quiet --db cocoda_api_kenom --collection mappings --query '{ uri: { $exists: true }, partOf: { $exists: false } }' --out $repo
/usr/bin/mongodump --quiet --db cocoda_api --collection mappings --query '{ uri: { $exists: true }, partOf: { $exists: false } }' --out $repo

# convert bson to json
for file in $repo/*/*.bson
do
  file_json=${file%*bson}ndjson
  bsondump --quiet --outFile $file_json $file
done
# add and commit
git -C $repo/ add .
if [ "`git -C $repo/ diff --cached --name-only`" ]
then
  date_adjusted=$(date --iso-8601=seconds)
  git -C $repo/ commit --date "$date_adjusted"  -m "$date_adjusted"
fi
