#! /bin/bash

# https://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/common.sh

target_inst=$1
shift
if [[ -z "$target_inst" ]]; then die "Usage: $0 <target inst>"; fi

init_arena "$ARENA"
init_build_dir "$target_inst"
init_target_dir "$target_inst"
init_aux_dir

make -j 4 -C "${build_dir}" O="${build_dir}" INSTALL_PATH="${target_dir}" INSTALL_MOD_PATH="${target_dir}" INSTALL_HDR_PATH="${target_dir}" modules_install firmware_install headers_install install

mkinitcpio -g ${target_dir}/initramfs-linux -k ${target_dir}/vmlinuz -r ${target_dir} -c ${aux_dir}/mkinitcpio.conf

# install into the image if it is mounted
target_dir=${HOME}/image/mnt
if mountpoint ${target_dir} >/dev/null; then
    # do not clobber image's header files under /usr/include 
    sudo make -j 3 -C "${build_dir}" O="${build_dir}" INSTALL_PATH="${target_dir}" INSTALL_MOD_PATH="${target_dir}/usr" modules_install firmware_install install
    sudo mkinitcpio -g ${target_dir}/initramfs-linux -k ${target_dir}/vmlinuz -r ${target_dir} -c ${aux_dir}/mkinitcpio.conf
else
    die "${target_dir} not mounted with the image"
fi 
