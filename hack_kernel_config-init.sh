#! /bin/bash

# https://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/common.sh

target_inst=$1
shift
config_method=$1
shift
if [[ -z "${target_inst}" || -z "${config_method}" ]]; then die "Usage: $0 <target inst> <kernel config method>"; fi

init_arena "$ARENA"
init_build_dir "$target_inst"

make O="${build_dir}" ${config_method}
