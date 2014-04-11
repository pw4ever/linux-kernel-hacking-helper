#! /bin/bash

function die {
cat > /dev/stderr <<-END
$1
END

exit 1; 
}

nbd_no=$1
arch_img=$2
part_no=$3
if [[ -z "$nbd_no" || -z "$arch_img" || -z "$part_no" ]]; then die "Usage: $0 <QEMU nbd no> <arch image name> <root partition number>"; fi

#sudo modprobe nbd max_part=16
sudo qemu-nbd -c /dev/nbd${nbd_no} ${HOME}/image/${arch_img}.img
sudo partprobe /dev/nbd${nbd_no}
sudo mount /dev/nbd${nbd_no}p${part_no} ${HOME}/image/mnt 
