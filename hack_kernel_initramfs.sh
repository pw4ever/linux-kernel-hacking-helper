#! /bin/bash

# https://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/common.sh

target_inst=$1
shift
if [[ -z "$target_inst" ]]; then die "Usage: $0 <target inst>"; fi

init_arena "$ARENA"
init_target_dir "$target_inst"
init_aux_dir

mkinitcpio -g ${target_dir}/initramfs-linux -k ${target_dir}/vmlinuz -r ${target_dir} -c ${aux_dir}/mkinitcpio.conf 
