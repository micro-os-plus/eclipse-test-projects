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

export PATH="$HOME/opt/gcc-arm-none-eabi-5_4-2016q3/bin":"$PATH"
export PATH="/Applications/GNU ARM Eclipse/QEMU/2.7.0-201611062027-dev/bin":"$PATH"
export PATH="/Applications/SEGGER/JLink_V60g":"$PATH"
export PATH="/opt/homebrew/bin":"$PATH"

# caffeinate bash "$parent/run-qemu.sh"
caffeinate bash "$parent/run-qemu-short.sh" --loops 1000
