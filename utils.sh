RED='\033[0;31m'
NC='\033[0m'

function error {
  # message to STDERR
  if [ -t 1 ]; then
    printf "$RED$1$NC\n" >&2	
  else
    echo "$1" >&2	
  fi	  
  exit "${2:-1}"  # exit code as specified or 1
}

if [[ $# -eq 0 ]]; then
  usage
  exit
fi

# remove a trailing slash from each argument
set -- ${@%/}

[[ "$1" =~ ^[a-z0-9.-]+$ ]] || error "invalid service name '$1'"

if [[ "$1" == "all" ]]; then
  grep -o '^[^#]*' services.txt | xargs -L 1 $0
  exit
fi
