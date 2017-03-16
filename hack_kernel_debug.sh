#! /bin/bash

# https://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/common.sh

target_inst=$1
shift
image=$1
shift
if [[ -z "$target_inst" ]]; then die "Usage: $0 <target inst>"; fi

init_arena "$ARENA"
init_build_dir "$target_inst"

cd "${build_dir}"
gdb -ex 'target remote :1234' ${build_dir}/vmlinux
