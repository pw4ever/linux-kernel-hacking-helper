#! /bin/bash

# https://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/common.sh

target_inst=$1
shift
image=$1
shift
if [[ -z "$target_inst" || -z "$image" ]]; then die "Usage: $0 <target inst> <disk image> [<more append options>] [<QEMU additional args>]"; fi

append_opt=$1
shift

init_arena "$ARENA"
init_build_dir "$target_inst"
init_target_dir "$target_inst"
image_dir=$HOME/image

qemu-system-x86_64 -kernel ${target_dir}/vmlinuz -initrd ${target_dir}/initramfs-linux -hda ${image_dir}/${image}.img -gdb tcp::1234 -append "root=$(cat ${image_dir}/${image}.uuid) ${append_opt}" $*
