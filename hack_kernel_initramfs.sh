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
target_dir=${ARENA}/target/${target_ver}
aux_dir=${ARENA}/aux
if [[ ! -d "$target_dir" || ! -d "$aux_dir" ]]; then die "Target or aux directory error."; fi

mkinitcpio -g ${target_dir}/initramfs-linux -k ${target_dir}/vmlinuz -r ${target_dir} -c ${aux_dir}/mkinitcpio.conf 
