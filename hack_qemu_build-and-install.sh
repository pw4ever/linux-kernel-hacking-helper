#! /bin/bash

function die {
cat > /dev/stderr <<-END
$1
END

exit 1; 
}

# over target_dir by defining it
if [[ -z "$target_dir" ]]; then
    target_dir=${HOME}/image/mnt
fi

# TRICK: "./configure --help" can prevent generate configure files and recompilation
if (( $# > 0 )); then
    ./configure --python=/usr/bin/python2 $*
else
    # rationale for the extra-cflags: http://the-hydra.blogspot.com/2011/04/getting-confused-when-exploring-qemu.html
    ./configure --extra-cflags="-save-temps" --python=/usr/bin/python2 --target-list=x86_64-linux-user,x86_64-softmmu --prefix=${target_dir}/usr/local
fi

make -j 8

# install into image if it is mounted
if mountpoint ${target_dir} 2>&1 >/dev/null; then
    # sudo is needed to install into image
    sudo make -j 8 install
else
    die "Mount the image under ${target_dir}"
fi 
