#!/bin/bash

# TODOs:
# - Support URLs and local files for reimport
# - Improve vocabulary filters (currently doesn't support scheme data only)
# - Add better error handling
# - Support other data like concordances?

function usage {
  echo "
Usage: $0 [-d data.txt] [-f] [-r] [-g <vocabulary filter>]

Offers easy importing of vocabularies into jskos-server instances via a list in data.txt.
NOTE: This is still experimental. Use with caution.

Options:
  -d    Specify the data which is used for import; defaults to data.txt
  -f    Force import even if vocabulary data already exists
  -r    Reset a vocabulary's concept data before importing
  -g    A grep filter used on data.txt

Note that -r currently only works if the scheme is given as a BARTOC URI.

Examples:
  $0                    # Imports all vocabularies in data.txt (ignores concepts if already exist)
  $0 -g node/18797      # Imports IxTheo (ignores concepts if already exist)
  $0 -g node/18797 -f   # Imports IxTheo, including concepts
  $0 -g node/18797 -r   # Imports IxTheo, resets its concepts, then reimports concepts
"
}

DATAFILE="data.txt"
FORCE="false"
RESET="false"
FILTER=""

while getopts 'd:frg:h' flag; do
  case "${flag}" in
    d) DATAFILE="${OPTARG}" ;;
    f) FORCE='true' ;;
    r) RESET='true' ;;
    g) FILTER="${OPTARG}" ;;
    h) usage
       exit 0 ;;
    *) usage
       exit 1 ;;
  esac
done

# Ask for confirmation to reimport all vocabularies
if [[ "$RESET" == "true" ]] && [[ -z "$FILTER" ]]; then
  read -p "Are you sure you want to reset all vocabularies? " -r
  if [[ ! $REPLY =~ ^[Yy]$ ]]
  then
    exit 0
  fi
fi


function handler {
  # TODO: How can I remove these functions from handler? If they are defined outside of it, they won't be available due to how we call it (see last line).
  ok() {
    echo "📗 $@"
  }
  warn() {
    echo "📙 $@"
  }
  error() {
    echo "📕 $@"
  }
  # Logs based on condition
  # Parameter 1: Condition (usually $?)
  # Parameter 2: Success string
  # Parameter 3: Failure string
  didSucceed () {
    echo
    if [[ $1 -eq 0 ]]; then
      ok $2
    else
      warn $3
    fi
  }
  # baseUrl will be in BASE_URL
  function getBaseUrl {
    if ! command -v jq &> /dev/null
    then
      BASE_URL=""
      echo
      warn "!!! WARNING: jq could not be found; will not import vocabulary. Run script with -f to import anyway. !!!"
      exit
    fi

    JSKOS_SERVER=$0
    BASE_URL=$(jq '.baseUrl' $JSKOS_SERVER/config/config.json)

    if [[ "$BASE_URL" == "null" ]]; then
      PORT=$(jq '.port' $JSKOS_SERVER/config/config.json)
      if [[ "$PORT" == "null" ]]; then
        PORT=3000
      fi
      BASE_URL="http://localhost:$PORT"
    fi

    # Remove leading/trailing " if necessary
    BASE_URL="${BASE_URL%\"}"
    BASE_URL="${BASE_URL#\"}"
    # Remove trailing slash
    BASE_URL=$(echo ${BASE_URL%/})
  }

  JSKOS_SERVER=$0
  SCHEME=$1
  echo
  echo "==================== importing $SCHEME (force=$FORCE, reset=$RESET) ===================="
  echo

  # TODO: This works only if scheme is given as BARTOC URI, but it should work for all cases.
  if [[ "$RESET" == "true" ]]; then
    yes | $JSKOS_SERVER/bin/reset.js -s $SCHEME
    didSucceed $? "Concept data was removed from jskos-server." "Concept data could not be removed from jskos-server."
    echo
  fi

  # Load scheme data from BARTOC if a BARTOC URI is given
  if [[ "$SCHEME" =~ ^http://bartoc.org ]]; then
    SCHEME_URI=$SCHEME
    SCHEME=https://bartoc.org/api/data?uri=$SCHEME
  fi
  $JSKOS_SERVER/bin/import.js scheme $SCHEME
  didSucceed $? "Vocabulary metadata was imported into jskos-server." "Import of vocabulary metadata into jskos-server failed."
  echo

  # TODO: Check if concept data exists already; if yes, stop here.
  if [[ "$FORCE" == "false" ]] && [[ "$RESET" == "false" ]] && [[ ! -z $SCHEME_URI ]]
  then
    getBaseUrl $JSKOS_SERVER
    CONCEPTS_LENGTH=$(curl -s "$BASE_URL/voc?uri=$SCHEME_URI" | jq '.[0] | .concepts | length')
    if [[ "$CONCEPTS_LENGTH" == "1" ]]; then
      warn "Concept data for $SCHEME_URI already exists. Run script with -f to import anyway."
      exit
    fi
  fi

  # Supports multiple concept files
  for CONCEPTS in "${@:2}"
  do
    $JSKOS_SERVER/bin/import.js concepts $CONCEPTS
    didSucceed $? "Concept data was imported into jskos-server." "Import of concept data into jskos-server failed."
    echo
  done

}

export -f handler
grep -o '^[^#]*' $DATAFILE | grep "$FILTER" | FORCE=$FORCE RESET=$RESET xargs -L 1 bash -c 'handler "$@"'
