<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

- [Linux kernel building/testing helper scripts](#linux-kernel-buildingtesting-helper-scripts)
	- [Cheatsheet](#cheatsheet)
		- [One-time setup](#one-time-setup)
		- [Build, install, and test the kernel](#build-install-and-test-the-kernel)
		- [Build, install, and test a kernel module](#build-install-and-test-a-kernel-module)
	- [Tips](#tips)
		- [Hack KVM with nested virtualization](#hack-kvm-with-nested-virtualization)
			- [Example](#example)
			- [Explanation](#explanation)
		- [Enable kernel debugging](#enable-kernel-debugging)
			- [Example](#example-1)
			- [Reference](#reference)

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
/home/wei/
cp $HOME/hacking/linux-kernel/helper/aux/mkinitcpio.conf $ARENA/aux/
modprobe nbd max_part=16
```

### Build, install, and test the kernel

Put a QEMU Linux OS image (e.g., a minimal [Arch Linux](https://www.archlinux.org/) installation) and its root fs UUID is under $HOME/image.

Suppose they are `$HOME/image/arch.img` and `$HOME/image/arch.uuid` from now on, and the `root` flesystem (`/`; with `/usr` on the same partition with `/`) is `/dev/sda2` in `arch.img`.

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
hack_kernel_test.sh 1 arch-base "kgdboc=kdb,ttyS0 kgdbwait kgdbcon" -vnc :2 -cpu qemu64,+vmx -net user -net nic,model=virtio -redir tcp:5907::5907 -serial 'pty'
```

### Build, install, and test a kernel module

```bash
hack_mod_build.sh 1 8 # build with kernel instance 1 in 8 parallel jobs
hack_mount.sh 1 arch 2 # if needed; see above
hack_mod_install.sh 1 # install into kernel instance 1 
hack_umount.sh 1 # if needed; see above
```

## Tips

### Hack KVM with nested virtualization

#### Example

```bash
hack_kernel_test.sh 2 arch-base "" -vnc :2 -cpu qemu64,+vmx -net user -net nic,model=virtio -redir tcp:5907::5907
```

#### Explanation

* -cpu qemu64,+vmx: This makes the virtual CPU inherits the Intel VT-x feature of the physical machine, which is required for launching a nested VM.

* -net user -net nic,model=virtio -redir tcp:5907::5907: This redirects the TCP port 5907 of the guest OS inside the (first-level) VM to the host OS.

This makes the (first-level) VM accessible from VNC port 2 (TCP port 5902) and the nested VM accessible from VNC port 7 (TCP port 5907) on the host machine.

### Enable kernel debugging

#### Example

```bash
hack_kernel_test.sh 2 arch "kgdboc=kdb,ttyS0 kgdbwait kgdbcon" -vnc :2 -cpu qemu64,+vmx -net user -net nic,model=virtio -redir tcp:5907::5907 -serial 'pty'
```
with the following output `char device redirected to /dev/pts/15 (label serial0)`

Then use GDB remote debugging to connect to it:
```bash
cd $ARENA/build/2
gdb vmlinux
```

After in GDB command line:
```bash
target remote /dev/pts/15
```

#### Reference

[Using kgdb, kdb and the kernel debugger internals](https://www.kernel.org/doc/htmldocs/kgdb/index.html)
