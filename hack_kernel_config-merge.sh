#! /bin/bash

# https://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source ${DIR}/common.sh

target_inst=$1
shift
if [[ -z "$target_inst" ]]; then die "Usage: $0 <N> [<config fragments>]*"; fi

init_arena "$ARENA"
init_build_dir "$target_inst"

scripts/kconfig/merge_config.sh -m -O "${build_dir}" "${build_dir}/.config" $*
