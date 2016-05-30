# Eclipse projects to build some µOS++++/CMSIS tests

To use this tests, you need to:

* clone this project locally
`git clone https://github.com/micro-os-plus/eclipse-test-projects.git eclipse-test-projects.git`
* clone the [µOS++ development tree](https://github.com/micro-os-plus/micro-os-plus-iii-tree) locally (.../micro-os-plus-iii-tree.git)
```
git clone https://github.com/micro-os-plus/micro-os-plus-iii-tree.git micro-os-plus-iii-tree.git
cd micro-os-plus-iii-tree.git
git submodule update --init --recursive
```
* in Eclipse, in Preferences -> General -> Workspace -> Linked Resource -> New...
`MICRO_OS_PLUS_LOC` as the absolute path of **micro-os-plus-iii-tree.git**

## The POSIX synthetic platform tests

* in Eclipse, import the **os-synthetic-posix-tests** project
* build the **test-cmsis-rtos-valid-{clang|gcc}-}{debug|release}** configurations
* run the executables

Note 1: currently only OS X is supported.

Note 2: some of the build configurations can be also used on GNU/Linux,
directly, even if their name refers to OS X, as long as the executables
required available. Changing toolchains is not recommended, since it
may lead to corrupted configurations. If changing configurations
succeeds, the language Dialect must be set again for both the C and
the C++ tools.

## path

```
export PATH=/usr/local/gcc-arm-none-eabi-5_3-2016q1/bin:$PATH
export PATH=/Users/ilg/Work/qemu/build/osx/qemu/gnuarmeclipse-softmmu:$PATH
export PATH=/Applications/SEGGER/JLink_V510s:$PATH
export PATH=/opt/homebrew/bin:$PATH

```

## Warnings

```
All:
-Wall -Wextra
-Wunused -Wuninitialized -Wmissing-declarations -Wconversion -Wpointer-arith -Wpadded -Wshadow -Wlogical-op -Waggregate-return -Wfloat-equal
C:
-Wmissing-prototypes -Wstrict-prototypes -Wbad-function-cast
C++:
-Wabi -Wctor-dtor-privacy -Wnoexcept -Wnon-virtual-dtor -Wstrict-null-sentinel -Wsign-promo
```
