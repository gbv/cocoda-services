#!/bin/bash -e

function usage {
  echo "Usage: $0 <name> | all"
  echo "Analyze source code of service in directory <name>. Expects service to be initialized."
}

function warn {
  echo "  $1!" 1>&2
}

. utils.sh

if [[ ! -d "$1" ]]; then
  warn "$1 is not installed"
  exit
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo -ne "$1\t$BRANCH\t"
cd $1

if [[ -f "package.json" ]]; then
  echo -ne "node\t"
  jq -r .version package.json

  [[ ! -f "package-lock.json" ]] && warn "Missing package-lock.json"

elif [[ -f "cpanfile" ]]; then
  echo "Perl"

else
  echo "Unknown"
fi

if [[ -f ".travis.yml" ]]; then
  warn ".travis.yml is depreacted"
else
  [[ ! -f ".github/workflows/test.yml" ]] && warn "missing .github/workflows/test.yml"
fi
