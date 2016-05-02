# Eclipse projects to build some µOS++++/CMSIS tests

To use this tests, you need to:

* clone this project locally
* clone the [µOS++ development tree](https://github.com/micro-os-plus/micro-os-plus-iii-tree) locally (.../micro-os-plus-iii-tree.git)
* in Eclipse, define `MICRO_OS_PLUS_LOC` as a **Workspace Linked Resource** to the absolute path of **micro-os-plus-iii-tree.git**

## The POSIX synthetic platform tests

* in Eclipse, import the **os-synthetic-posix-tests** project
* build the **test-cmsis-rtos-valid-{clang|gcc}-}{debug|release}** configurations
* run the executables
