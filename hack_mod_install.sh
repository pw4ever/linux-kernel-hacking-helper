#! /bin/bash

function die {
cat > /dev/stderr <<-END
$1
END

exit 1; 
}

target_ver=$1
if [[ -z "$target_ver" ]]; then die "Usage: $0 <N>"; fi

if [[ -z "$ARENA" ]]; then ARENA=$HOME/arena; fi
if [[ ! -d "$ARENA" ]]; then die "${ARENA} is not a directory."; fi
ARENA=${ARENA%%/} # remove trailing /
build_dir=${ARENA}/build/${target_ver}
target_dir=${ARENA}/target/${target_ver}

#if [[ ! -d "$build_dir" || ! -d "$target_dir" || ! -d "aux_dir" ]]; then die "Build/target/auxiliary directory error."; fi

make -j4 -C ${build_dir} O=${build_dir} INSTALL_MOD_PATH=${target_dir} M=${PWD} modules_install

# install into the image if it is mounted
target_dir=${HOME}/image/mnt
if mountpoint ${target_dir} >/dev/null; then
    #krelease=$(cat ${build_dir}/include/config/kernel.release)
    sudo make -j4 -C ${build_dir} O=${build_dir} INSTALL_MOD_PATH=${target_dir} M=${PWD} modules_install
else
    die "Mount the image under ${target_dir}"
fi 
