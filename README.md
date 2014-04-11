<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

- [Linux kernel building/testing helper scripts](#linux-kernel-buildingtesting-helper-scripts)
	- [Setup](#setup)
	- [Initializing the environment](#initializing-the-environment)
		- [Command](#command)
		- [Purpose](#purpose)
		- [Syntax](#syntax)
		- [Parameters](#parameters)
		- [Example](#example)
	- [Build guest OS kernel](#build-guest-os-kernel)
		- [command](#command)
		- [Purpose](#purpose-1)
		- [Syntax](#syntax-1)
		- [Parameters](#parameters-1)
		- [Example](#example-1)
	- [Mount and unmount VM disk image](#mount-and-unmount-vm-disk-image)
		- [Command](#command-1)
		- [Purpose](#purpose-2)
		- [Syntax](#syntax-2)
		- [Parameters](#parameters-2)
		- [Example](#example-2)
		- [Note](#note)
	- [Install kernel](#install-kernel)
		- [Command](#command-2)
		- [Purpose](#purpose-3)
		- [Syntax](#syntax-3)
		- [Parameters](#parameters-3)
		- [Example](#example-3)
	- [Launch kernel in QEMU Virtual Machine (VM)](#launch-kernel-in-qemu-virtual-machine-vm)
		- [Command](#command-3)
		- [Purpose](#purpose-4)
		- [Syntax](#syntax-4)
		- [Parameters](#parameters-4)
		- [Example](#example-4)
	- [Tips](#tips)
		- [Hack KVM with nested virtualization](#hack-kvm-with-nested-virtualization)
			- [Example](#example-5)
			- [Explanation](#explanation)
		- [Enable kernel debugging](#enable-kernel-debugging)
			- [Example](#example-6)
			- [Reference](#reference)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Linux kernel building/testing helper scripts

These scripts help set up multiple Linux kernel building instances and facilitate their test using QEMU/KVM on Linux.

## Setup

### Installing the scripts

```bash
mkdir -p $HOME/hacking/linux-kernel
cd $HOME/hacking/linux-kernel
git clone https://github.com/pw4ever/linux-kernel-hacking-helper.git helper
mkdir -p $HOME/arena/linux
```

### Add environment variables

In shell per-user init file (e.g., `.profile` which is sourced by `.bashrc`/`.zshrc`):
```bash
export PATH=$HOME/hacking/linux-kernel/helper/:$PATH
export ARENA=$HOME/arena/linux/
```

### Initializing the environment

#### Command

hack_init.sh

#### Purpose

Initializing the environment for the rest of the toolkit by populating the current user's home directories with required directories and files.

#### Syntax

```bash
hack_init.sh n
```

#### Parameters

* n: Maximal number of kernel variants to be accommodated.

#### Example

```bash
hack_init.sh 100
```

Prepare the file-system structure required to support up to 100 virtual machines; legitimate instances for target kernel are from 1 to 100.

## Build and test the kernel

### Build guest OS kernel

#### command

hack_kernel_build.sh

#### Purpose

Build, with optional configuration and parallelism, guest OS kernel.

#### Syntax

```bash
hack_kernel_build.sh n [parallel [config]]
```

#### Parameters

* n: The target kernel instance.

* parallel: The (optional) number of parallel building jobs; recommended value is twice the number of CPU cores.

* config: The (optinal) config method, e.g., nconfig for the Linux kernel.

#### Example

```bash
hack_kernel_build.sh 2 8
```

Build target kernel instance 2 with 8 parallel jobs using existing configuration for that instance (perhaps created by a previous run of this command with a config option).

### Mount and unmount VM disk image

#### Command

hack_mount.sh and hack_umount.sh

#### Purpose

Mount and unmount VM disk image so that the kernel instance built by hack_kernel_build.sh can be later installed by hack_kernel_install.sh; this makes the kernel loadable modules for the customized kernel accessible from inside the VM.

#### Syntax

```bash
hack_mount.sh nbd name root-part
hack_umount.sh nbd
```

#### Parameters

* nbd: Network Block Device (NBD) device to be used for mounting the image.

* name: The name of the VM disk image (without the .img suffix) to be found at the image directory under the user’s home directory.

* root-part: The partition for the root filesystem of the VM image.

#### Example

```bash
hack_mount.sh 2 arch-base 2
hack_umount.sh 2
```

Mount the root filesystem of the VM disk image image/arch-base.img under user's home directory to NBD device 2 (the device file for the root filesystem is /dev/nbd2p2 in Linux). Unmount the partition later with hack_umount.sh.

#### Note

The `nbd` device must be loaded:
```bash
modprobe nbd max_part=16
```

To do this on boot, create `/etc/modules-load.d/nbd.conf`:
```bash
nbd
```
and `/etc/modprobe.d/ndb.conf`:
```bash
options nbd max_part=16
```

### Install kernel

#### Command

hack_kernel_install.sh

#### Purpose

Install the kernel instance so it can be later launched.

#### Syntax

```bash
hack_kernel_install.sh n
```

#### Parameters

* n: The kernel instance to be installed; VM image should have been mounted by hack_mount.sh before this and un-mounted by hack_umount.sh after this.

#### Example

```bash
hack_kernel_install.sh 2
```

Install kernel instance 2.

### Launch kernel in QEMU Virtual Machine (VM)

#### Command

hack_kernel_test.sh

#### Purpose

Launch customized kernel with a disk image in a VM.

#### Syntax

```bash
hack_kernel_test.sh n vm-image kernel-opts vmm-opts
```

#### Parameters

* n: Kernel instance to be launched.

* vm-image: Basename of the disk image file (without the .img suffix).

* kernel-opts: Options to be passed to the kernel.

* vmm-opts: Options to be passed to the underlying VMM.

#### Example

```
hack_kernel_test.sh 2 arch-base "" -vnc :2
```

Launch kernel instance 2 with the image/arch-base.img disk image file using default kernel options on VNC channel 5902 opened by the VMM (in this case, QEMU/KVM).

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
hack_kernel_test.sh 2 arch-base "kgdboc=kdb,ttyS0 kgdbwait kgdbcon" -vnc :2 -cpu qemu64,+vmx -net user -net nic,model=virtio -redir tcp:5907::5907 -serial 'pty'
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
