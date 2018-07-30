#! /bin/bash

# https://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/common.sh

target_inst=$1
shift
par_job=$1
shift
if [[ -z "$target_inst" ]]; then die "Usage: $0 <target inst> [<# of parallel jobs>]"; fi

init_arena "$ARENA"
init_build_dir "$target_inst"

if [[ -n "$par_job" ]]; then
    make_jobs="-j $par_job"
fi

pre_build_setup

make ${make_jobs} -C ${build_dir} O=${build_dir} M=${PWD} modules
