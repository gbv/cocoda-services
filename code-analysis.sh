#!/bin/bash -e

function usage {
  echo "Usage: $0 <name> | all"
  echo "Analyze source code of service in directory <name>. Expects service to be initialized."
}

. utils.sh

if [[ ! -d "$1" ]]; then
  error "$1 is not installed"
  exit
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo -ne "$1\t$BRANCH\t"
cd $1

if [[ -f "package.json" ]]; then
  echo -ne "node\t"
  jq -r .version package.json

  [[ ! -f "package-lock.json" ]] && error "Missing package-lock.json"

elif [[ -f "cpanfile" ]]; then
  echo "Perl"

else
  echo "Unknown"
fi

if [[ -f ".travis.yml" ]]; then
  error ".travis.yml is deprecated, use GitHub Action instead!"
else
  [[ ! -f ".github/workflows/test.yml" ]] && error "missing .github/workflows/test.yml"
fi
