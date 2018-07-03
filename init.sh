#!/bin/bash -e

function usage {
  echo "Usage: $0 <name>"
  echo "Ininitalize service in directory <name> by installation of dependencies."
}

. utils.sh

echo "Initialize dependencies of $1"
cd $1

if [[ -f "package.json" ]]; then
  echo "Detected Node service"
  npm install
elif [[ -f "cpanfile" ]]; then
  echo "Detected Perl service"
  export PERL5LIB=$(pwd)/local/lib/perl5
  export PERL_LOCAL_LIB_ROOT=$(pwd)/local/lib/perl5
  export PERL_MM_OPT="INSTALL_BASE=$(pwd)/local"
  cpanm --installdeps --skip-satisifed --notest .
else
  error "Unknown service type!"
fi
