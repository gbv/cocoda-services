#!/bin/bash -e

function usage {
  echo "Usage: $0 <name>"
  echo "Pulls updates via git and restarts service"
}

. utils.sh

[[ -d "$1/.git" ]] || error "missing $1/.git"

# Update via git
git -C $1 fetch origin master
git -C $1 reset --hard origin/master

# Install dependencies
./init.sh $1

# Restart service
pm2 restart $1
