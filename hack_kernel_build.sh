#! /bin/bash

function die {
cat > /dev/stderr <<-END
$1
END

exit 1; 
}

target_ver=$1
if [[ -z "$target_ver" ]]; then die "Usage: $0 <N> [<make -j jobs> [<config method>]]"; fi

if [[ -z "$ARENA" ]]; then ARENA=$HOME/arena; fi
if [[ ! -d "$ARENA" ]]; then die "${ARENA} is not a directory."; fi
ARENA=${ARENA%%/} # remove trailing /
build_dir=${ARENA}/build/${target_ver}
if [[ ! -d "$build_dir" ]]; then die "Build directory error."; fi

# $3 could be kernel config methods such as "xconfig" or "nconfig"; "make help" for "help"
if [[ -n "$3" ]]; then make O=${build_dir} $3; fi 

if [[ -n "$2" ]]; then
    make_jobs="-j $2"
fi

make ${make_jobs} O=${build_dir}
