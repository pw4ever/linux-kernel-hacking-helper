<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

- [Summary](#summary)
  - [In scope](#in-scope)
  - [Out of scope](#out-of-scope)
- [Cheatsheet](#cheatsheet)
- [One-time setup](#one-time-setup)
- [Build and test multiple instances of kernel](#build-and-test-multiple-instances-of-kernel)
  - [QEMU GDBServer-based kernel test and debug (recommended)](#qemu-gdbserver-based-kernel-test-and-debug-recommended)
  - [Virtual-serial-port-based kernel test and debug (not recommended)](#virtual-serial-port-based-kernel-test-and-debug-not-recommended)
- [Build, install, and test a loadable kernel module](#build-install-and-test-a-loadable-kernel-module)
- [Tips](#tips)
  - [List state of and optionally act on each kernel build instance](#list-state-of-and-optionally-act-on-each-kernel-build-instance)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Summary

## In scope

- Manage building, installing, and testing-with-QEMU multiple instances of Linux kernel and loadable kernel modules (LKMs).
- [Easy defaults](#cheatsheet) while exposing the full capability of the underlying Makefile-based kernel build infrastructure.
- Implement with ubiquitous programs (e.g., `bash`) to reduce the friction of using this tool.


## Out of scope

- Set up kernel/module build dependencies on your distro.
- [Comprehensively document](https://github.com/cirosantilli/linux-kernel-module-cheat) building/testing kernel/LKHs on various architectures/environments.


# Cheatsheet

Follow [one-time setup](#one-time-setup) to clone the repo, get testing OS qcow2 image, and (optional but recommended) setting up environment variables.

The following list of commands use defaults (e.g., instance 1, `nproc`+2 jobs, and assuming `arch.{img,uuid}` have the testing OS qcow2 image/rootfs-UUID) to demonstrate the end-to-end process.

Build and install kernel instance 1 into `$LKHH_IMAGE/arch.img`.
```bash
# pushd $HOME/project/linux # `linux` is the root of the kernel repo "https://github.com/torvalds/linux"
lkhh-kernel-make -t mrproper
lkhh-kernel-make -t defconfig
lkhh-kernel-merge-config -- $LKHH_BIN/config/debug
lkhh-kernel-make -t all
lkhh-mount
lkhh-kernel-install # requires `dracut` for creating initrd
lkhh-umount
```

Testing the built kernel image with QEMU.
```bash
lkhh-kernel-test-with-qemu -- -m 1024m
# lkhh-kernel-test-with-qemu -- -m 512m -enable-kvm # KVM really helps with performance
# lkhh-kernel-test-with-qemu -- -m 512m -enable-kvm -net nic -net user # if you want networking
```

While the QEMU instance is running, debug the kernel with GDB.
```bash
lkhh-kernel-debug
```

Create a new barebone LKM project `hello` (from the default template `lkm_barebone`; see `lkhh-new -h` for help), build, and install it.
```bash
# lkhh-mount # if the testing OS image has not been mounted yet
proj=hello; lkhh-new -p "$proj" -f -- "pushd \"$proj\"; lkhh-module-make -I; popd"
# lkhh-umount # if the testing OS image is mounted
```
Afterwards, use `sudo modprobe hello` and `sudo modprobe -r hello` inside the QEMU session (see above) to load/unload the `hello` module.

Build and install an existing LKM.
```bash
# pushd $HOME/project/my_lkm # `my_lkm` is the root of the LKM, with the minimal module Makefile (e.g., "obj-m := my_lkm.o")
# lkhh-mount # if the testing OS image has not been mounted yet
lkhh-module-make -I
# lkhh-umount # if the testing OS image is mounted
```

Alternatively, create a dual in/out-tree Makefile for an existing source-only project.
```bash
lkhh-module-init -h  # Show help.
lkhh-module-init  # The LKM project is assumed to be rooted at pwd, and there goes the Makefile.
lkhh-module-init -m hello  # The LKM project is rooted at `hello`; `hello/Makefile` is created if it does not exist...
```

Optionally, a simple main file can be created in addition to the Makefile.
```bash
lkhh-module-init -m hello -f  # ... or forcibly if `hello/Makefile` already exists.
lkhh-module-init -m hello -M -f  # A LKM project is created under `hello`: `hello/Makefile` and `hello/main.c`.
pushd hello; make; popd;  # ... afterwards, build the project use `make`.
```

# One-time setup

First things first. Ensure you have [tools for building kernel](https://github.com/torvalds/linux/blob/master/Documentation/process/changes.rst#current-minimal-requirements); consult your distro documentation for instruction. For example, Arch Linux makes this [really easy](https://wiki.archlinux.org/index.php/Kernel/Traditional_compilation#Install_the_core_packages) with the `base-devel` package group. By design, LKHH does NOT help you with this because of the moving target and numerous various environments that user may want to use this.

Install `qemu` if you want to testing the built kernel/LKMs.

```bash
export LKHH_DIR="$HOME/hacking/linux-kernel"  # rootdir of LKHH; default to parent of PWD of the running script
export LKHH_BIN="$LKHH_DIR/bin"  # rootdir of LKHH scripts; default to PWD of the running script
export LKHH_ARENA="$LKHH_DIR/arena"  # rootdir for kernel instance build/target dirs; default to "$LKHH_DIR/arena"
export LKHH_IMAGE="$LKHH_DIR/image"  # rootdir of OS images used by "lkhh-kernel-test-with-qemu"; default to "$LKHH_DIR/image"
export LKHH_LINUX="$HOME/project/linux"  # rootdir of the kernel source Git repo; default to "$HOME/project/linux".

mkdir -p "$LKHH_DIR"

pushd "$LKHH_DIR"
git clone https://github.com/pw4ever/linux-kernel-hacking-helper.git bin && export PATH="$LKHH_BIN:$PATH"
popd

# see help: lkhh-init -h
lkhh-init -i 10
# # (optional) in addition to initialize 10 build instances, also download and decompress a testing OS image `arch-clean.{img,uuid}` into `$LKHH_IMAGE` (recommend to use `aria2` for fast parallel download; fall back to `wget` otherwise).
# lkhh-init -i 10 -d
# # recommendation is to rename `arch-clean.{img,uuid}` into `arch.{img,uuid}` for testing below

sudo modprobe nbd nbds_max=32 max_part=64
```

# Build and test multiple instances of kernel

Put a QEMU Linux OS image (e.g., a minimal [Arch Linux](https://www.archlinux.org/) installation) and its root filesystem UUID under `$LKHH_IMAGE` (see [One-time setup](#one-time-setup) for the default path setup).

Suppose they are `$LKHH_IMAGE/arch.img` and `$LKHH_IMAGE/arch.uuid` from now on, and the `root` flesystem (`/`; with `/usr` on the same partition with `/`) is `/dev/sda2` in `arch.img` ([Follow this page to download such an Arch Linux qcow2 image](https://github.com/pw4ever/linux-kernel-hacking-helper/releases/tag/arch-clean); `sudo`-able username/password: user/user).

```bash
# pushd $HOME/project/linux # `linux` is the root of the kernel repo "https://github.com/torvalds/linux"
# see LKHH tool help, e.g., `lkhh-kernel-make -h`
# see kernel make help: `lkhh-kernel-make` or `lkhh-kernel-make -t help`

lkhh-kernel-make -i 1 -t clean  # remove generated files
# lkhh-kernel-make -i 1 -t mrproper  # remove generated file + config + backup files
lkhh-kernel-make -i 1 -t defconfig  # config kernel with defconfig
lkhh-kernel-merge-config -i 1 $LKHH_BIN/config/kgdb  # merge kgdb support in config
# lkhh-kernel-merge-config -i 1 $LKHH_BIN/config/debug  # at least use the "debug" config to allow symbolic debugging of the kernel using GDB (see below)
lkhh-kernel-make -i 1 -j 8 -t all  # build kernel instance 1 with 8 parallel jobs

lkhh-mount -n 3 -i arch -p 2  # mount device '/dev/sda2' (the root partition) of '$LKHH_IMAGE/arch.img' with '/dev/ndb3' onto '$LKHH_IMAGE/mnt/3'
lkhh-kernel-install -i 1 -n 3  # install kernel instance 1 into '$LKHH_IMAGE/mnt/3' (mounted partition of '$LKHH_IMAGE/arch.img' as above); require `dracut` to create initrd
lkhh-umount -n 3  # umount '$LKHH_IMAGE/mnt/3' and diassociate '/dev/nbd3'

# read kdb doc at https://www.kernel.org/doc/htmldocs/kgdb/index.html
```
## QEMU GDBServer-based kernel test and debug (recommended)

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

## Virtual-serial-port-based kernel test and debug (not recommended)

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

# Build, install, and test a loadable kernel module

```bash
# lkhh-mount # if the testing OS image has not been mounted yet
lkhh-module-make -i 1 -I # build module with kernel instance 1 ("-i 1") and install the module ("-I")
# lkhh-umount # if the testing OS image is mounted
```

# Tips

## List state of and optionally act on each kernel build instance

After using `lkhh-init` to set up instances of kernel build, using `lkhh-kernel-list`  to find out the state of and optionally act on each of the instance.

In all examples below, assume `lkhh-init -i 10` was used, instance 1 was configured and built, and instance 2 was configured only.

List all non-empty instances.
```bash
lkhh-kernel-list
#1:	configured(4.20.0+)	source@(/data/upstream/linux)	built(vmlinux is up to date with .config)
#2:	configured(4.20.0+)	source@(/data/upstream/linux)
```

List all instances, including empty ones
```bash
lkhh-kernel-list -a
#1:	configured(4.20.0+)	source@(/data/upstream/linux)	built(vmlinux is up to date with .config)
#2:	configured(4.20.0+)	source@(/data/upstream/linux)
#3:
#4:
#5:
#6:
#7:
#8:
#9:
#10:
```
List path for each instance build directory.
```bash
lkhh-kernel-list -a --foreach 'xargs'
#1:	configured	source@(/home/wei/upstream/linux)	built(vmlinux is older than .config)
#/home/wei/hacking/linux-kernel/arena/build/1
#2:	configured	source@(/home/wei/upstream/linux)
#/home/wei/hacking/linux-kernel/arena/build/2
#3:
#/home/wei/hacking/linux-kernel/arena/build/3
#4:
#/home/wei/hacking/linux-kernel/arena/build/4
#5:
#/home/wei/hacking/linux-kernel/arena/build/5
#6:
#/home/wei/hacking/linux-kernel/arena/build/6
#7:
#/home/wei/hacking/linux-kernel/arena/build/7
#8:
#/home/wei/hacking/linux-kernel/arena/build/8
#9:
#/home/wei/hacking/linux-kernel/arena/build/9
#10:
#/home/wei/hacking/linux-kernel/arena/build/10
```

List contents for each instance build directory.
```bash
lkhh-kernel-list -a --foreach 'xargs ls -am'
#1:	configured	source@(/home/wei/upstream/linux)	built(vmlinux is older than .config)
#., .., .16063.dwo, .16070.dwo, .16077.dwo, .16084.dwo, .16091.dwo, .16098.dwo,
#.16105.dwo, .16112.dwo, .16122.dwo, .16132.dwo, .16139.dwo, .16146.dwo,
#.16153.dwo, .16160.dwo, .16167.dwo, .16177.dwo, .16999.dwo, .17032.dwo,
#.17074.dwo, .17284.dwo, .17468.dwo, .17813.dwo, .17928.dwo, .18171.dwo,
#.18835.dwo, .19492.dwo, .19665.dwo, .19836.dwo, .20036.dwo, .20205.dwo,
#.20449.dwo, .22240.dwo, .22242.dwo, .22326.dwo, .22373.dwo, .22626.dwo,
#.22656.dwo, .22690.dwo, .23615.dwo, .24026.dwo, .24050.dwo, .24077.dwo,
#.24336.dwo, .24359.dwo, .24375.dwo, .28829.dwo, .39890.dwo, .39919.dwo,
#.39947.dwo, .48315.dwo, .48334.dwo, .48341.dwo, .48354.dwo, .48365.dwo,
#.48372.dwo, .50078.dwo, .50118.dwo, .50146.dwo, .61848.dwo, .61887.dwo,
#.61905.dwo, .70589.dwo, .70596.dwo, .70603.dwo, .70610.dwo, .70617.dwo,
#.70624.dwo, .70631.dwo, .70638.dwo, .70645.dwo, .70652.dwo, .70659.dwo,
#.70666.dwo, .70673.dwo, .70680.dwo, .70687.dwo, .70702.dwo, .71326.dwo,
#.71333.dwo, .71340.dwo, .71347.dwo, .71354.dwo, .71361.dwo, .71368.dwo,
#.71375.dwo, .71382.dwo, .71389.dwo, .71396.dwo, .71403.dwo, .71410.dwo,
#.71417.dwo, .71424.dwo, .71434.dwo, .71681.dwo, .71719.dwo, .71744.dwo,
#.71906.dwo, .72020.dwo, .72186.dwo, .72218.dwo, .72351.dwo, .72692.dwo,
#.72752.dwo, .72972.dwo, .73153.dwo, .73361.dwo, .73543.dwo, .73711.dwo,
#.74664.dwo, .74697.dwo, .74818.dwo, .74821.dwo, .74854.dwo, .74883.dwo,
#.74892.dwo, .74925.dwo, .74977.dwo, .75270.dwo, .75276.dwo, .75852.dwo,
#.76194.dwo, .76311.dwo, .76351.dwo, .76403.dwo, .76487.dwo, .76603.dwo,
#.77042.dwo, .77055.dwo, .77566.dwo, .77573.dwo, .77580.dwo, .77587.dwo,
#.77594.dwo, .77601.dwo, .77614.dwo, .77621.dwo, .77628.dwo, .77635.dwo,
#.77642.dwo, .77650.dwo, .77657.dwo, .77664.dwo, .77671.dwo, .77681.dwo,
#.78046.dwo, .78078.dwo, .78183.dwo, .78185.dwo, .78232.dwo, .78262.dwo,
#.78279.dwo, .78309.dwo, .78358.dwo, .78512.dwo, .78604.dwo, .79460.dwo,
#.79546.dwo, .79618.dwo, .79655.dwo, .79720.dwo, .79856.dwo, .79952.dwo,
#.80462.dwo, .80475.dwo, .config, .config.old, .missing-syscalls.d,
#.tmp_System.map, .tmp_kallsyms1.S, .tmp_kallsyms1.o, .tmp_kallsyms2.S,
#.tmp_kallsyms2.o, .tmp_versions, .tmp_vmlinux1, .tmp_vmlinux2, .version,
#.vmlinux.cmd, Makefile, Module.symvers, System.map, arch, block, built-in.a,
#certs, crypto, drivers, firmware, fs, include, init, ipc, kernel, lib, mm,
#modules.builtin, modules.order, net, scripts, security, sound, source, tools,
#usr, virt, vmlinux, vmlinux-gdb.py, vmlinux.o
#2:	configured	source@(/home/wei/upstream/linux)
#., .., .config, Makefile, include, scripts, source
#3:
#., ..
#4:
#., ..
#5:
#., ..
#6:
#., ..
#7:
#., ..
#8:
#., ..
#9:
#., ..
#10:
#., ..
```
