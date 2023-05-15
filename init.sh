#!/bin/bash -e

function usage {
  echo "Usage: $0 <name> | all"
  echo "Initialize service in directory <name> by installation of dependencies."
}

. utils.sh

echo "Initialize dependencies of $1"
cd $1


# "NODE_ENV=development" is necessary because we want npm ci to include dev dependencies as they might be needed for the build.

if [[ -f "package-lock.json" ]]; then

  echo "Detected Node service (via package-lock.json)"
  NODE_ENV=development npm ci --force
  npm run build || echo "no build script found"

elif [[ -f "package.json" ]]; then
  
  echo "Detected Node service"
  NODE_ENV=development npm i --force --no-package-lock
  npm run build || echo "no build script found"

elif [[ -f "cpanfile" ]]; then
  
  echo "Detected Perl service"
  eval $(perl -Mlocal::lib=local)
  cpanm --installdeps --notest .

else
  error "Unknown service type!"
fi
