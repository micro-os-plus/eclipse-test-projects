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

Note: currently only OS X is supported.
