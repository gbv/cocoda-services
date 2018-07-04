#!/bin/bash -e

function usage {
  echo "Usage: $0 <name> | all"
  echo "Initialize service in directory <name> by installation of dependencies."
}

. utils.sh

echo "Initialize dependencies of $1"
cd $1

if [[ -f "package.json" ]]; then
  
  echo "Detected Node service"
  npm install
  if grep --quiet '^ \+build$' package.json; then
    npm run build
  fi

elif [[ -f "cpanfile" ]]; then
  
  echo "Detected Perl service"
  eval $(perl -Mlocal::lib=local)
  cpanm --installdeps --notest .

else
  error "Unknown service type!"
fi
