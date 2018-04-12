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

export PATH="$HOME/Library/xPacks/@gnu-mcu-eclipse/arm-none-eabi-gcc/7.2.1-1.1/.content/bin":$PATH
export PATH=/Applications/GNU\ ARM\ Eclipse/QEMU/2.7.0-201610290751/bin:$PATH

# caffeinate bash "$parent/run-qemu.sh"
caffeinate bash "$parent/run-qemu.sh" --loops 1000 --all

arm-none-eabi-g++ --version

