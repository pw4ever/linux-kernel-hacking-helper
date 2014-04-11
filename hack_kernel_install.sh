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
aux_dir=${ARENA}/aux

#debug
[[ -d "$build_dir" ]] || echo $build_dir
[[ -d "$target_dir" ]] || echo $target_dir
[[ -d "$aux_dir" ]] || echo $aux_dir

#if [[ ! -d "$build_dir" || ! -d "$target_dir" || ! -d "aux_dir" ]]; then die "Build/target/auxiliary directory error."; fi

make -j4 O=${build_dir} INSTALL_PATH=${target_dir} INSTALL_MOD_PATH=${target_dir} INSTALL_HDR_PATH=${target_dir} modules_install firmware_install headers_install install

mkinitcpio -g ${target_dir}/initramfs-linux -k ${target_dir}/vmlinuz -r ${target_dir} -c ${aux_dir}/mkinitcpio.conf

# install into the image if it is mounted
target_dir=${HOME}/image/mnt
if mountpoint ${target_dir} >/dev/null; then
    # no need to install header inside
    sudo make -j3 -C ${build_dir} O=${build_dir} INSTALL_PATH=${target_dir} INSTALL_MOD_PATH=${target_dir}/usr modules_install firmware_install install
    sudo mkinitcpio -g ${target_dir}/initramfs-linux -k ${target_dir}/vmlinuz -r ${target_dir} -c ${aux_dir}/mkinitcpio.conf
else
    die "Mount the image under ${target_dir}"
fi 
