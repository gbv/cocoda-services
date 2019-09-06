#!/bin/bash -e

function usage {
  echo "Usage: $0 <name> [<git-url>] | all"
  echo "Install and initialize service."
}

. utils.sh

NAME=$1
URL=$2
BRANCH=$3

if [[ -d $NAME ]]; then
  echo "Directory $NAME already exists, skipping"
  exit
fi

if [[ -z "$URL" ]]; then
  URL=https://github.com/gbv/$NAME.git
fi

if [[ -z "$BRANCH" ]]; then
  BRANCH_TEXT="default branch"
else
  BRANCH_TEXT="branch: $BRANCH"
fi
echo "Install service $NAME from $URL ($BRANCH_TEXT)"

git clone $URL $NAME
if [[ ! -z "$BRANCH" ]]; then
  git -C $NAME checkout $BRANCH
fi

./init.sh $NAME
./start.sh $NAME

echo
