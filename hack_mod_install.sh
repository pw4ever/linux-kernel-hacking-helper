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

make -C "${build_dir}" O="${build_dir}" INSTALL_MOD_PATH="${target_dir}" M="${PWD}" modules_install

# install into the image if it is mounted
target_dir=${HOME}/image/mnt
if mountpoint ${target_dir} >/dev/null; then
    sudo make -C "${build_dir}" O="${build_dir}" INSTALL_MOD_PATH="${target_dir}/usr" M="${PWD}" modules_install
else
    die "${target_dir} not mounted with the image"
fi 
