#!/bin/bash

# TODOs:
# - Support URLs and local files for reimport
# - Improve vocabulary filters (currently doesn't support scheme data only)
# - Add better error handling
# - Support other data like concordances?

function usage {
  cat << EOF
Usage: ./manage.sh <command> [<vocabulary filter>]

Offers easy importing of vocabularies into jskos-server instances via a list in data.txt.
NOTE: This is still experimental. Use with caution.

Commands:
  import    Import vocabularies and their concept data into jskos-server instances
  reimport  Remove concept data for vocabularies, then run import

<vocabulary filter> can be given to filter the end of the second column in data.txt.
Note that reimport currently only works if the scheme is given as a BARTOC URI.
EOF
}

if [[ $# -eq 0 ]]; then
  usage
  exit
fi

COMMAND=$1
FILTER=$2

# Ask for confirmation to reimport all vocabularies
if [[ "$COMMAND" == "reimport" ]] && [[ -z "$FILTER" ]]; then
  read -p "Are you sure you want to reset all vocabularies? " -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    exit 1
  fi
fi

function handler {
  JSKOS_SERVER=$0
  SCHEME=$1
  echo
  echo "==================== $COMMAND-ing $SCHEME ===================="
  echo

  # TODO: This works only if scheme is given as BARTOC URI, but it should work for all cases.
  if [[ "$COMMAND" == "reimport" ]]; then
    yes | $JSKOS_SERVER/bin/reset.js -s $SCHEME
  fi

  # Load scheme data from BARTOC if a BARTOC URI is given
  if [[ "$SCHEME" =~ ^http://bartoc.org ]]; then
    SCHEME=https://bartoc.org/api/data?uri=$SCHEME
  fi
  $JSKOS_SERVER/bin/import.js scheme $SCHEME

  # Supports multiple concept files
  for CONCEPTS in "${@:2}"
  do
    $JSKOS_SERVER/bin/import.js concepts $CONCEPTS
  done

  echo
}

export -f handler
grep -o '^[^#]*' data.txt | grep "$FILTER " | COMMAND=$COMMAND xargs -L 1 bash -c 'handler "$@"'
