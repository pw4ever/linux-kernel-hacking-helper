#! /bin/bash

function die {
cat > /dev/stderr <<-END
$1
END

exit 1; 
}

target_ver=$1
if [[ -z "$target_ver" ]]; then die "Usage: $0 <N> [<make -j jobs>]"; fi

if [[ -z "$ARENA" ]]; then ARENA=$HOME/arena; fi
if [[ ! -d "$ARENA" ]]; then die "${ARENA} is not a directory."; fi
ARENA=${ARENA%%/} # remove trailing /
build_dir=${ARENA}/build/${target_ver}
if [[ ! -d "$build_dir" ]]; then die "Build directory error."; fi

if [[ -n "$2" ]]; then
    make_jobs="-j $2"
fi

make ${make_jobs} -C ${build_dir} O=${build_dir} M=${PWD}
