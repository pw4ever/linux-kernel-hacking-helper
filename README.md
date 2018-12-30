<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

- [Linux kernel building/testing helper scripts](#linux-kernel-buildingtesting-helper-scripts)
  - [Cheatsheet](#cheatsheet)
    - [One-time setup](#one-time-setup)
    - [Build, install, and test the kernel](#build-install-and-test-the-kernel)
      - [QEMU GDBServer-based kernel test and debug (recommended)](#qemu-gdbserver-based-kernel-test-and-debug-recommended)
      - [Virtual-serial-port-based kernel test and debug (not recommended)](#virtual-serial-port-based-kernel-test-and-debug-not-recommended)
    - [Build, install, and test a kernel module](#build-install-and-test-a-kernel-module)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Linux kernel building/testing helper scripts

These scripts help set up multiple Linux kernel building instances and facilitate their test using QEMU/KVM on Linux.

## Cheatsheet

### One-time setup

```bash
export LKHH_DIR="$HOME/hacking/linux-kernel"
export LKHH_BIN="$LKHH_DIR/bin"
export LKHH_ARENA="$LKHH_DIR/arena"
export LKHH_IMAGE="$LKHH_DIR/image"

mkdir -p "$LKHH_DIR"

pushd "$LKHH_DIR"
git clone https://github.com/pw4ever/linux-kernel-hacking-helper.git bin && export PATH="$LKHH_BIN:$PATH"
popd

# see help: lkhh-init -h
lkhh-init -i 10

sudo modprobe nbd nbds_max=32 max_part=64
```

### Build, install, and test the kernel

Put a QEMU Linux OS image (e.g., a minimal [Arch Linux](https://www.archlinux.org/) installation) and its root fs UUID is under $HOME/image.

Suppose they are `$HOME/image/arch.img` and `$HOME/image/arch.uuid` from now on, and the `root` flesystem (`/`; with `/usr` on the same partition with `/`) is `/dev/sda2` in `arch.img` ([Follow this page to download such an Arch Linux qcow2 image](https://github.com/pw4ever/linux-kernel-hacking-helper/releases/tag/arch-clean); `sudo`-able username/password: user/user).

```bash
# pushd $HOME/project/linux # cd into the kernel source root (https://github.com/torvalds/linux)
# see tool help: lkhh-kernel-make -h
# see kernel make help: lkhh-kernel-make

lkhh-kernel-make -i 1 -t clean  # remove generated files
# lkhh-kernel-make -i 1 -t mrproper  # remove generated file + config + backup files
lkhh-kernel-make -i 1 -t defconfig  # config kernel with defconfig
lkhh-kernel-merge-config -i 1 $HOME/hacking/linux-kernel/helper/config/kgdb  # merge kgdb support in config
lkhh-kernel-make -i 1 -j 8 -t all  # build kernel instance 1 with 8 parallel jobs

lkhh-mount -n 3 -i arch -p 2  # mount device '/dev/sda2' (the root partition) of '$LKHH_IMAGE/arch.img' with '/dev/ndb3' onto '$LKHH_IMAGE/mnt/3'
lkhh-kernel-install -i 1 -n 3  # install kernel instance 1 into '$LKHH_IMAGE/mnt/3' (mounted partition of '$LKHH_IMAGE/arch.img' as above)
lkhh-kernel-mkinitcpio -i 1 -n 3  # (optional w/ 'lkhh-kernel-install') install initramsf for kernel instance 1 into '$LKHH_IMAGE/mnt/3'
lkhh-umount -n 3  # umount '$LKHH_IMAGE/mnt/3' and diassociate '/dev/nbd3'

# read kdb doc at https://www.kernel.org/doc/htmldocs/kgdb/index.html
```
#### QEMU GDBServer-based kernel test and debug (recommended)

Get help.

```bash
lkhh-kernel-test-with-qemu -h
```

A simple example using defaults (kernel instance 1, 'arch' OS image, no additional kernel cmdline, using 'x86_64' QEMU system emulator).

```bash
# launch kernel instance 1 with 'arch' OS image in QEMU
# the parameters after '--' is passed directly to qemu-system-*
lkhh-kernel-test-with-qemu -- -enable-kvm -m 2048M
```
Connect to the guest machine through VNC port :2 (5902). Nested QEMU session can be observed at VNC port :7 (5907).

```bash
# launch kernel instance 1 in QEMU with nested virtualization and kernel debugging support
lkhh-kernel-test-with-qemu -i 1 -I arch -- -enable-kvm -m 2048M -vnc :2 -cpu host -net nic -net user,hostfwd=tcp::5907-:5907
```

`lkhh-kernel-debug -i <N>` will launch a GDB session with matching symbols (assuming debug support is properly configured for the kernel before building; see [here](https://github.com/torvalds/linux/blob/master/Documentation/dev-tools/gdb-kernel-debugging.rst#setup) for hints on `CONFIG_*`; `lkhh-kernel-merge-config -i 1 -- "$LKHH_BIN/config/debug"` can help here) to break into the corresponding QEMU instance launched by `lkhh-kernel-test-with-qemu -i <N>`.

```bash
# launch GDB session for the default (1) kernel instance
lkhh-kernel-debug

# being explicit
lkhh-kernel-debug -i 1
```

By default, `lkhh-kernel-test-with-qemu` and `lkhh-kernel-debug` will use TCP port 1234 as GDB server port. This can be changed by the `-g` parameter for both commands. Use `-h` for help as always.

Once in the GDB session, use 'c' to release the target and `Ctrl-c` to break-in again. Refer to [kernel documentation](https://github.com/torvalds/linux/blob/master/Documentation/dev-tools/gdb-kernel-debugging.rst) for further information.

#### Virtual-serial-port-based kernel test and debug (not recommended)

Suppose `lkhh-kernel-merge-config $LKHH_BIN/config/kgdb` has been used to merge `kgdb` and `kdb` support prior to kernel building using `lkhh-ernel-make -t all`.

Suppose nested virtualization is [enabled](https://www.kernel.org/doc/Documentation/virtual/kvm/nested-vmx.txt) (i.e., `kvm-intel` is loaded with `nested=1`).

```bash
# launch kernel instance 1 in QEMU with nested virtualization and kernel debugging support
lkhh-kernel-test-with-qemu -i 1 -I arch -c 'kgdboc=kms,kbd,ttyS0,115200 kgdbwait kgdbcon' -- -enable-kvm -m 2048M -vnc :2 -cpu qemu64,+vmx -net nic -net user,hostfwd=tcp::5907-:5907 -serial pty
```

Connect to the guest machine through VNC port :2 (5902) and PTY device `/dev/pts/<nn>` (`<nn>` is some integer; this will be printed out by QEMU; QEMU doc says pty is available only on Linux). Nested QEMU session can be observed at VNC port :7 (5907).

After `lkhh-kernel-debug -i 1 -g /dev/pts/<nn> -- -b 115200` to enter the GDB debug session. This is equivalent to the following GDB commands:

```bash
set remotebaud 115200
target remote /dev/pts/<nn>
```

In the guest, [break in](http://landley.net/kdocs/Documentation/DocBook/xhtml-nochunks/kgdb.html#usingKDB) to kgdb/kdb with `echo g > /proc/sysrq-trigger` as `root`. We can also [switch](http://landley.net/kdocs/Documentation/DocBook/xhtml-nochunks/kgdb.html#idp1634992) between kgdb and kdb.

### Build, install, and test a kernel module

```bash
hack_mod_build.sh 1 8 # build with kernel instance 1 in 8 parallel jobs
hack_mount.sh 1 arch 2 # if needed; see above
hack_mod_install.sh 1 # install into kernel instance 1
hack_umount.sh 1 # if needed; see above
```
