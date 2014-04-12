<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

- [Linux kernel building/testing helper scripts](#linux-kernel-buildingtesting-helper-scripts)
	- [Cheatsheet](#cheatsheet)
		- [One-time setup](#one-time-setup)
		- [Build, install, and test the kernel](#build-install-and-test-the-kernel)
		- [Build, install, and test a kernel module](#build-install-and-test-a-kernel-module)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Linux kernel building/testing helper scripts

These scripts help set up multiple Linux kernel building instances and facilitate their test using QEMU/KVM on Linux.

## Cheatsheet

### One-time setup

```bash
mkdir -p $HOME/hacking/linux-kernel
cd $HOME/hacking/linux-kernel
git clone https://github.com/pw4ever/linux-kernel-hacking-helper.git helper
mkdir -p $HOME/arena/linux
export PATH=$HOME/hacking/linux-kernel/helper/:$PATH
export ARENA=$HOME/arena/linux/
hack_init.sh 100
cp $HOME/hacking/linux-kernel/helper/aux/mkinitcpio.conf $ARENA/aux/
modprobe nbd max_part=16
```

### Build, install, and test the kernel

Put a QEMU Linux OS image (e.g., a minimal [Arch Linux](https://www.archlinux.org/) installation) and its root fs UUID is under $HOME/image.

Suppose they are `$HOME/image/arch.img` and `$HOME/image/arch.uuid` from now on, and the `root` flesystem (`/`; with `/usr` on the same partition with `/`) is `/dev/sda2` in `arch.img` (There is [an Arch Linux qcow2 image](http://cs.iupui.edu/~pengw/download/arch-clean.tar) hosted on [my homepage](http://cs.iupui.edu/~pengw)).

```bash
# cd $HOME/project/linux # cd into the directory of kernel source
hack_kernel_config-init.sh 1 defconfig # config kernel with defconfig
hack_kernel_config-merge.sh 1 $HOME/hacking/linux-kernel/helper/config/kgdb # merge kgdb support in config
hack_kernel_build.sh 1 8 # build kernel instance 1 with 8 parallel jobs
hack_mount.sh 1 arch 2 # mount `/dev/sda2` (the root partition) of `$HOME/image/arch.img` with host's `/dev/ndb1` onto `$HOME/image/mnt/`
hack_kernel_install.sh 1 # install kernel instance 1 with initramfs into `$HOME/image/mnt/` (which has the mounted `$HOME/image/arch.img`)
hack_kernel_initramfs.sh 1 # optional, already done in hack_kernel_install.sh, need $ARENA
hack_umount.sh 1 # umount `$HOME/image/mnt/` and diassociate `/dev/nbd1`
# read kdb doc at https://www.kernel.org/doc/htmldocs/kgdb/index.html
# launch kernel instance 1 in QEMU with nested virtualization and kernel debugging support
hack_kernel_test.sh 1 arch 'kgdboc=kms,kbd,ttyS0,115200 kgdbwait kgdbcon' -enable-kvm -m 1024M -vnc :2 -cpu qemu64,+vmx -net nic -net user,hostfwd=tcp::5907-:5907 -serial pty
```

Connect to the guest machine through VNC port :2 (5902) and PTY device `/dev/pts/nn` (nn is some integer; this will be printed out by QEMU; QEMU doc says pty is available only on Linux). Nested QEMU session can be observed at VNC port :7 (5907).

After `hack_kernel_debug.sh 1` and enter GDB:

```bash
set remotebaud 115200
target remote /dev/pts/nn
```

In the guest, [break in to kgdb/kdb with `echo g > /proc/sysrq-trigger` as `root`](https://www.kernel.org/doc/htmldocs/kgdb/EnableKGDB.html). We can also [switch between kgdb and kdb](https://www.kernel.org/doc/htmldocs/kgdb/switchKdbKgdb.html).

### Build, install, and test a kernel module

```bash
hack_mod_build.sh 1 8 # build with kernel instance 1 in 8 parallel jobs
hack_mount.sh 1 arch 2 # if needed; see above
hack_mod_install.sh 1 # install into kernel instance 1 
hack_umount.sh 1 # if needed; see above
```
