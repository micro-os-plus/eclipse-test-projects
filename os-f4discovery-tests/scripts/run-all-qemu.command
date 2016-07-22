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

export PATH=/usr/local/gcc-arm-none-eabi-5_3-2016q1/bin:$PATH
export PATH=/Users/ilg/Work/qemu/build/osx/qemu/gnuarmeclipse-softmmu:$PATH
export PATH=/Applications/SEGGER/JLink_V510s:$PATH
export PATH=/opt/homebrew/bin:$PATH

bash "$parent/run-qemu.sh"
# bash "$parent/run-qemu.sh" --loops 1000
