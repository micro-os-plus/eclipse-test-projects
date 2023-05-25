#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script=$0
if [[ "${script}" != /* ]]
then
  # Make relative path absolute.
  script=$(pwd)/$0
fi

parent="$(dirname ${script})"
echo $parent

export PATH="${HOME}/Library/xPacks/@gnu-mcu-eclipse/arm-none-eabi-gcc/7.2.1-1.1.5/.content/bin":$PATH
export PATH="${HOME}/Library/xPacks/@gnu-mcu-eclipse/qemu/2.8.0-3.1/.content/bin":$PATH

# caffeinate bash "$parent/run-qemu.sh"
caffeinate bash "$parent/run-qemu.sh" --loops 1000 --all

arm-none-eabi-g++ --version

