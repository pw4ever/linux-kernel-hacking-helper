#! /bin/bash

# https://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/common.sh

nbd_no=$1
shift
arch_img=$1
shift
part_no=$1
shift
if [[ -z "$nbd_no" || -z "$arch_img" || -z "$part_no" ]]; then die "Usage: $0 <QEMU nbd no> <arch image name> <root partition number>"; fi

#sudo modprobe nbd max_part=16
sudo qemu-nbd -c /dev/nbd${nbd_no} ${HOME}/image/${arch_img}.img
sudo partprobe /dev/nbd${nbd_no}
sudo mount /dev/nbd${nbd_no}p${part_no} ${HOME}/image/mnt 
