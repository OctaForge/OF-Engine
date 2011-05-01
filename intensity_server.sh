#!/bin/sh

# Do a chdir to the dir with this script in it
abspath="$(cd "${0%/*}" 2>/dev/null; echo "$PWD"/"${0##*/}")"
path_only=`dirname "$abspath"`
cd ${path_only}

# find out needed information
os=$(uname -s)
arch=$(uname -m)
archp=$(uname -p)

PARAMS="-q${HOME}/.octaforge_client"
PREFIX="./bin"
if [ -f ${PREFIX}/OF_Server_${os}-${arch} ]; then
    ${PREFIX}/OF_Server_${os}-${arch} ${PARAMS} $@
else
    if [ -f ${PREFIX}/OF_Server_${os}-${archp} ]; then
        ${PREFIX}/OF_Server_${os}-${archp} ${PARAMS} $@
    else
        echo "Binary for your OS (${os}) and/or architecture (${arch}) was not found."
        echo "You must compile one. If you'll compile, it would be good if you sent the binary to developers,"
        echo "to help support of OctaForge on various platforms."
        read end
        exit 1
    fi
fi

exit 0

