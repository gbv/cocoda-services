#!/bin/bash -e

function usage {
  echo "Usage: $0 <name> | all"
  echo "Pulls updates via git and restarts service"
}

. utils.sh

[[ -d "$1/.git" ]] || error "missing $1/.git"

# Update via git
git -C $1 fetch --tags origin master
git -C $1 reset --hard origin/master

# Install dependencies
./init.sh $1

# Restart service
./start.sh $1
