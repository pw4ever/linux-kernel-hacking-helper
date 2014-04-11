#! /bin/bash

function die {
cat > /dev/stderr <<-END
$1
END

exit 1; 
}

nbd_no=$1
if [[ -z "$nbd_no" ]]; then die "Usage: $0 <QEMU nbd no>"; fi

#$1 - nbd number

sudo umount $HOME/image/mnt
if [[ $? == 0 ]]; then
    sudo qemu-nbd -d /dev/nbd$nbd_no
fi
