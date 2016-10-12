# Eclipse projects to build some µOS++/CMSIS++ tests

## Projects

### os-f4discovery-tests

These tests run on the STM32F4DISCOVERY board (or the QEMU emulator).

### os-synthetic-posix-tests

These tests run on the synthetic POSIX platform, on top of macOS.

## Prerequisites

These projects have several dependencies to code available from xPacks. To satisfy these dependencies it is necessary to run the `generate.sh` shell scripts.

### macOS

All scripts were created on macOS, and the ones suffixed with `.command` are specific to macOS.

As usual for development machines, the _Apple Xcode Command Line Tools_ must be installed.

### GNU/Linux

The scripts were also tested on several GNU/Linux distributions, and should be fine.

On Ubuntu be sure you have `git` and `curl` available:

```
suso apt-get git curl
```

For other distributions, similar commands must be issued.

### Windows

The scripts were also tested on Windows **MSYS2**, **Git Shell**, and on the new [Windows Subsystem for Linux](https://msdn.microsoft.com/commandline/wsl/about).

The only difference is the lack of symbolic links, so `--symlink` should not be used and instead `--link` is fully functional, but the `generate.sh` script should be executed after updating the git repositories in `/.xpacks`.

For those who insist on native Windows, separate PowerShell scripts would be required, but considering Microsoft's move towards Linux, this would probably not be worth the effort. Anyway, if you manage to create them, please consider improving your karma and contribute them back to the community.

## How to use

To use any of these projects, you need to:


* clone this project locally
```
$ git clone https://github.com/micro-os-plus/eclipse-test-projects.git eclipse-test-projects.git
```
* in each project, generate the code required to satisfy the dependencies; on macOS, double click the `scripts/generate.mac.command` in Finder; on other platforms, go to the project folder and run the `generate.sh` script
```
$ bash scripts/generate.sh
```
* in Eclipse, import the projects into your workspace, **without copying**
* build all configurations


## Paths

```
export PATH=/usr/local/gcc-arm-none-eabi-5_4-2016q3/bin:$PATH
export PATH=/Users/ilg/Work/qemu/build/osx/qemu/gnuarmeclipse-softmmu:$PATH
export PATH=/Applications/SEGGER/JLink_V60g:$PATH
export PATH=/opt/homebrew/bin:$PATH

```

## Warnings

```
All:
-Wall -Wextra
-Wunused -Wuninitialized -Wmissing-declarations -Wconversion -Wpointer-arith -Wshadow -Wlogical-op -Wfloat-equal
C:
-Wmissing-prototypes -Wstrict-prototypes -Wbad-function-cast
C++:
-Wabi -Wctor-dtor-privacy -Wnoexcept -Wnon-virtual-dtor -Wstrict-null-sentinel -Wsign-promo
```
