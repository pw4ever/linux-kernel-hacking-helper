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

lkhh-init -i 100 # or: lkhh-init --instance 100

modprobe nbd max_part=16
```

### Build, install, and test the kernel

Put a QEMU Linux OS image (e.g., a minimal [Arch Linux](https://www.archlinux.org/) installation) and its root fs UUID is under $HOME/image.

Suppose they are `$HOME/image/arch.img` and `$HOME/image/arch.uuid` from now on, and the `root` flesystem (`/`; with `/usr` on the same partition with `/`) is `/dev/sda2` in `arch.img` ([Follow this page to download such an Arch Linux qcow2 image](https://github.com/pw4ever/linux-kernel-hacking-helper/releases/tag/arch-clean); `sudo`-able username/password: user/user).

```bash
# cd $HOME/project/linux # cd into the directory of kernel source
hack_kernel_config-init.sh 1 mrproper # clobber stale object files
hack_kernel_config-init.sh 1 defconfig # config kernel with defconfig
hack_kernel_config-merge.sh 1 $HOME/hacking/linux-kernel/helper/config/kgdb # merge kgdb support in config
hack_kernel_build.sh 1 8 # build kernel instance 1 with 8 parallel jobs
hack_mount.sh 1 arch 2 # mount `/dev/sda2` (the root partition) of `$HOME/image/arch.img` with host's `/dev/ndb1` onto `$HOME/image/mnt/`
hack_kernel_install.sh 1 # install kernel instance 1 with initramfs into `$HOME/image/mnt/` (which has the mounted `$HOME/image/arch.img`)
hack_kernel_initramfs.sh 1 # optional, already done in hack_kernel_install.sh, need $ARENA
hack_umount.sh 1 # umount `$HOME/image/mnt/` and diassociate `/dev/nbd1`
# read kdb doc at https://www.kernel.org/doc/htmldocs/kgdb/index.html
```
#### QEMU GDBServer-based kernel test and debug (recommended)

```bash
# launch kernel instance 1 in QEMU with nested virtualization and kernel debugging support
hack_kernel_test.sh 1 arch '' -enable-kvm -m 1024M -vnc :2 -cpu qemu64,+vmx -net nic -net user,hostfwd=tcp::5907-:5907
```

Connect to the guest machine through VNC port :2 (5902). Nested QEMU session can be observed at VNC port :7 (5907).

`hack_kernel_debug.sh 1` should automatically break into the target kernel (with `target remote :1234`, matching the argument for QEMU's `-gdb` option in `hack_kernel_test.sh`). Use 'c' to release the target and `Ctrl-c` to break-in again. Refer to [kernel documentation](https://github.com/torvalds/linux/blob/master/Documentation/dev-tools/gdb-kernel-debugging.rst) for further information.

#### Virtual-serial-port-based kernel test and debug (not recommended)

```bash
# launch kernel instance 1 in QEMU with nested virtualization and kernel debugging support
hack_kernel_test.sh 1 arch 'kgdboc=kms,kbd,ttyS0,115200 kgdbwait kgdbcon' -enable-kvm -m 1024M -vnc :2 -cpu qemu64,+vmx -net nic -net user,hostfwd=tcp::5907-:5907 -serial pty
```

Connect to the guest machine through VNC port :2 (5902) and PTY device `/dev/pts/nn` (nn is some integer; this will be printed out by QEMU; QEMU doc says pty is available only on Linux). Nested QEMU session can be observed at VNC port :7 (5907).

After `hack_kernel_debug.sh 1` and enter GDB:

```bash
set remotebaud 115200
target remote /dev/pts/nn
```

In the guest, [break in to kgdb/kdb with `echo g > /proc/sysrq-trigger` as `root`](http://landley.net/kdocs/Documentation/DocBook/xhtml-nochunks/kgdb.html#usingKDB). We can also [switch between kgdb and kdb](http://landley.net/kdocs/Documentation/DocBook/xhtml-nochunks/kgdb.html#idp1634992).

### Build, install, and test a kernel module

```bash
hack_mod_build.sh 1 8 # build with kernel instance 1 in 8 parallel jobs
hack_mount.sh 1 arch 2 # if needed; see above
hack_mod_install.sh 1 # install into kernel instance 1 
hack_umount.sh 1 # if needed; see above
```
