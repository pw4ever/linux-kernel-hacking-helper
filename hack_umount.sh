#! /bin/bash

# https://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/common.sh

nbd_no=$1
shift
if [[ -z "$nbd_no" ]]; then die "Usage: $0 <QEMU nbd no>"; fi

sudo umount $HOME/image/mnt
if [[ $? == 0 ]]; then
    sudo qemu-nbd -d /dev/nbd${nbd_no}
fi
