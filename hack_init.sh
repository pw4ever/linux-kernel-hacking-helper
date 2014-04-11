#! /bin/bash


function die {
cat > /dev/stderr <<-END
$1 [<max n>]
END

exit 1; 
}

if [[ -z "$ARENA" ]]; then ARENA=$HOME/arena; fi
if [[ -z "$1" ]]; then N=3; else N=$1; fi
# the ARENA
for i in $(seq 1 $N); do mkdir -p ${ARENA}/{target,build}/$i; done
mkdir -p ${ARENA}/aux

# the image
mkdir -p $HOME/image/mnt
