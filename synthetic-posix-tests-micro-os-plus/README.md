# µOS++ tests running on synthetic POSIX (macOS)

These applications run on the synthetic POSIX platform and perform various tests

- test-cmsis-rtos-valid-clang-{debug|release}
- test-cmsis-rtos-valid-gcc-{debug|release}
- test-cmsis-rtos-valid-gcc5-{debug|release}
- test-cmsis-rtos-valid-gcc6-{debug|release}
- test-mutex-stress-clang-{debug|release}
- test-mutex-stress-gcc-{debug|release}
- test-mutex-stress-gcc5-{debug|release}
- test-rtos-clang-{debug|release}
- test-rtos-gcc-{debug|release}
- test-rtos-gcc5-{debug|release}
- test-rtos-gcc6-{debug|release}

## Preliminary

The content of the xPacks is not part of the repository, and must be dynamically generated. Until the XCDL utility will be available, the `generated` folder should be created with the `scripts/generate.sh` script.

```
bash scripts/generate.sh
```

## Build details

### Include folders

- `generated/micro-os-plus-iii/include`
- `generated/micro-os-plus-iii/include/cmsis-plus/legacy`
- `generated/posix-arch/include`
- `generated/arm-cmsis/driver/include`

CMSIS RTOS validator:
- `generated/arm-cmsis-ros-validator/arm/include`
- `generated/arm-cmsis-ros-validator/cmsis-plus/include`
- `generated/arm-cmsis-ros-validator/cmsis-rtos-valid/include`

Mutex stress:
- `generated/micro-os-plus-iii/tests/mutex-stress/include`

RTOS:
- `generated/micro-os-plus-iii/tests/rtos/include`

Semaphore stress:
- `generated/micro-os-plus-iii/tests/sema-stress/include`

### Source folders

- `generated/micro-os-plus-iii/src`
- `generated/posix-arch/src`

CMSIS RTOS validator:
- `generated/arm-cmsis-ros-validator/arm/src`
- `generated/arm-cmsis-ros-validator/arm/cmsis-plus/src`

Mutex stress:
- `generated/micro-os-plus-iii/tests/mutex-stress/src`

RTOS:
- `generated/micro-os-plus-iii/tests/rtos/src`

Semaphore stress:
- `generated/micro-os-plus-iii/tests/sema-stress/src`

### Symbols

To access the XOPEN definitions, it is necessary to set `_XOPEN_SOURCE`:
- `_XOPEN_SOURCE=700L`

### Compile options

The µOS++ code uses modern C++ features, and for this it is necessary to use a recent GCC version (v5.x or highrer) and to specify `-std=gnu++1y` in the GCC command line.

### Additional settings

- for `generated/arm-cmsis-rtos-validator/arm/src`, to silence C warnings in clang, use `-c -fmessage-length=0 -pipe -Weverything -Wno-documentation-unknown-command -Wno-empty-translation-unit -Wno-missing-prototypes -Wno-missing-declarations -Wno-padded -Wno-unused-parameter -Wno-format -Wno-sign-conversion -Wno-conversion -Wno-unused-function -Wno-sign-compare -Wno-reserved-id-macro -Wno-missing-variable-declarations -Wno-cast-qual -Wno-missing-noreturn -Wno-switch-enum -Wno-format-nonliteral -Wno-unused-macros -Wno-undef -Wno-date-time`

- for `generated/arm-cmsis-rtos-validator/arm/src`, to silence C warnings in GCC[56], use `-c -fmessage-length=0 -pipe  -Wno-unused-parameter -Wno-pointer-to-int-cast -Wno-unused-function -Wno-sign-compare`
