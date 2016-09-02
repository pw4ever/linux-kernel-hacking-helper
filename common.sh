#!/bin/bash

function die {
cat > /dev/stderr <<-END
$1
END

exit 1; 
}

# @param arena: optional
# @output ARENA
function init_arena {
local arena=$1
if [[ -z "$arena" ]]; then ARENA=$HOME/arena; fi
mkdir -p "$ARENA"
if [[ ! -d "$ARENA" ]]; then die "${ARENA} is not a directory."; fi
ARENA=${ARENA%%/} # remove trailing /
}

# @param target_inst
# @output build_dir
function init_build_dir {
local target_inst=$1
build_dir=${ARENA}/build/${target_inst}
if [[ ! -d "$build_dir" ]]; then die "Build directory error."; fi
}

# @param target_inst
# @output target_dir
function init_target_dir {
local target_inst=$1
target_dir=${ARENA}/target/${target_inst}
if [[ ! -d "$target_dir" ]]; then die "Target directory error."; fi
}

# @output aux_dir
function init_aux_dir {
aux_dir=${ARENA}/aux
if [[ ! -d "${aux_dir}" ]]; then die "Auxiliary directory error."; fi
}

