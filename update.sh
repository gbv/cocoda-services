#!/bin/bash -e

function usage {
  echo "Usage: $0 <name> | all"
  echo "Pulls updates via git and restarts service"
}

# Handle script is called from different directory -> allows calling the script without parameter if inside a service directory
# TODO: Maybe transfer this to start.sh and install.sh as well?
SCRIPT_DIR=$(dirname "$0")
if [[ $SCRIPT_DIR != "." ]]; then
  NAME="${1:-$(basename "$(pwd)")}"
  cd $SCRIPT_DIR
  ./update.sh "$NAME"
  exit
fi

. utils.sh

[[ -d "$1/.git" ]] || error "missing $1/.git"

# Update via git
git -C $1 fetch --tags
git -C $1 fetch --all
git -C $1 checkout -- package.json || true # workaround for unwanted changes in package.json if necessary
git -C $1 checkout -- package-lock.json || true # workaround for unwanted changes in package-lock.json if necessary
git -C $1 pull
git -C $1 reset --hard

# Install dependencies
./init.sh $1

# Restart service
./start.sh $1
