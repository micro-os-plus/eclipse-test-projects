# µOS++ with the FreeRTOS scheduler running on STM32F4DISCOVERY

These applications are functionally similar to those in the [f4discovery-tests-micro-os-plus](https://github.com/micro-os-plus/eclipse-test-projects/tree/master/f4discovery-tests-micro-os-plus) project, except they use the FreeRTOS implementation instead of the µOS++ Cortex-M implementation.

They run on the STM32F4DISCOVERY board and perform various tests:

- test-cmsis-rtos-valid-{debug|release}
- test-mutex-stress-{debug|release}
- test-rtos-{debug|release}
- test-sema-stress-{debug|release}

## Preliminary

The content of the xPacks is not part of the repository, and must be dynamically generated. Until the XCDL utility will be available, the `generated` folder should be created with the `scripts/generate.sh` script.

```
bash scripts/generate.sh
```

## Build details

### Include folders

- `generated/cube-mx/Inc`
- `generated/arm-cmsis/core/include`
- `generated/arm-cmsis/driver/include`
- `generated/freertos/ARM_CM3`
- `generated/freertos/cmsis-plus/include`
- `generated/freertos/FreeRTOS/include`
- `generated/micro-os-plus-iii/include`
- `generated/stm32f4-cmsis/stm32f407xx/include`
- `generated/stm32f4-hal/include`
- `generated/micro-os-plus-iii/include/cmsis-plus/legacy`
- `include`

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

- `generated/cube-mx/Src`
- `generated/freertos/ARM_CM3`
- `generated/freertos/FreeRTOS/src`
- `generated/freertos/cmsis-plus/src`
- `generated/micro-os-plus-iii/src`
- `generated/stm32f4-cmsis/stm32f407xx/src`
- `generated/stm32f4-hal/src`
- `src`

CMSIS RTOS validator:
- `generated/arm-cmsis-ros-validator/arm/src`
- `generated/arm-cmsis-ros-validator/arm/cmsis-plus/src`

Mutex stress:
- `generated/micro-os-plus-iii/tests/mutex-stress/src`

RTOS:
- `generated/micro-os-plus-iii/tests/rtos/src`

Semaphore stress:
- `generated/micro-os-plus-iii/tests/sema-stress/src`

### Compile options

The µOS++ code uses modern C++ features, and for this it is necessary to use a recent GCC version (v5.x or highrer) and to specify `-std=gnu++1y` in the GCC command line.

### Additional settings

- for `generated/stm32f4-hal/src`, to silence C warnings, use `-Wno-sign-conversion -Wno-padded -Wno-conversion -Wno-unused-parameter -Wno-bad-function-cast -Wno-sign-compare`
- for `generated/arm-cmsis-rtos-validator/arm/src`, to silence C warnings, use `-Wno-missing-prototypes -Wno-missing-declarations -Wno-padded -Wno-unused-parameter -Wno-format -Wno-sign-conversion -Wno-conversion -Wno-unused-function -Wno-sign-compare`
- for `generated/freertos/ARM_CM3/port.c`, to silence C warnings, use `-Wno-conversion`

## Semihosting

To simplify testing, this test uses the ARM semihosting API to access the host; this is enabled via `OS_USE_SEMIHOSTING_SYSCALLS` defined on the compiler command line. To run, semihosting normally requires an active debugger connection with the debugged board. However, the µOS++ exception handlers are enhanced with code to fake the semihosting calls if the debugger connection is not active (the JTAG/SWD cable is not connected). Unfortunately these features are available only for ARMv7M devices, so, for small Cortex-M0/M0+ devices, the debugger connection is manadatory.

For standalone applications, remove `OS_USE_SEMIHOSTING_SYSCALLS` and possibly add `-ffreestanding` to the compiler command line.
