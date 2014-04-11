#! /bin/bash

# https://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/common.sh

N=$1
shift
if [[ -z "$N" ]]; then die "Usage: $0 <total inst>"; fi

init_arena $ARENA

# the ARENA
for i in $(seq 1 $N); do mkdir -p ${ARENA}/{target,build}/$i; done
mkdir -p ${ARENA}/aux

# the image
mkdir -p $HOME/image/mnt
