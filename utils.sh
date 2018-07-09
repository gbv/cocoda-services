function error {
  echo "$1" >&2	  # message to STDERR
  exit "${2:-1}"  # exit code as specified or 1
}

if [[ $# -eq 0 ]]; then
  usage
  exit
fi

# remove a trailing slash from each argument
set -- ${@%/}

[[ "$1" =~ ^[a-z0-9-]+$ ]] || error "invalid service name '$1'"

if [[ "$1" == "all" ]]; then
  grep -o '^[^#]*' services.txt | xargs -L 1 $0
  exit
fi
