#!/bin/bash -e

function usage {
  echo "Usage: $0 <name> [<git-url>] | all"
  echo "Install and initialize service."
}

. utils.sh

NAME=$1
URL=$2

if [[ -d $1 ]]; then
  echo "Directory $1 already exists, skipping"
  exit
fi

if [[ -n "$URL" ]]; then
  URL=https://github.com/gbv/$NAME.git
fi

echo "Install service $1 from $2"

git clone $2 $1

./init.sh $1
