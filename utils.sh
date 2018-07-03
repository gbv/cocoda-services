function error {
  echo "$1" >&2	  # message to STDERR
  exit "${2:-1}"  # exit code as specified or 1
}

if [[ $# -eq 0 ]]; then
  usage
  exit
fi

[[ "$1" =~ ^[a-z-]+$ ]] || error "invalid service name '$1'"

if [[ "$1" == "all" ]]; then
  xargs -L 1 $0 < services.txt
  exit
fi
