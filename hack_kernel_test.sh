#! /bin/bash

function die {
cat > /dev/stderr <<-END
$1
END

exit 1; 
}

target_ver=$1
shift
image=$1
shift
if [[ -z "$target_ver" || -z "$image" ]]; then die "Usage: $0 <N> <disk image> [<more append options>] [<QEMU additional args>]"; fi
append_opt=$1
shift

if [[ -z "$ARENA" ]]; then ARENA=$HOME/arena; fi
if [[ ! -d "$ARENA" ]]; then die "${ARENA} is not a directory."; fi
ARENA=${ARENA%%/} # remove trailing /
target_dir=${ARENA}/target/${target_ver}
image_dir=$HOME/image
if [[ ! -d "$target_dir" || ! -d "$image_dir" ]]; then die "Target or image directory error."; fi

qemu-system-x86_64 -kernel ${target_dir}/vmlinuz -initrd ${target_dir}/initramfs-linux -hda ${image_dir}/${image}.img -append "root=$(cat ${image_dir}/${image}.uuid) ${append_opt}" -enable-kvm -m 1024 "$@"
