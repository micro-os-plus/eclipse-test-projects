#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script=$0
if [[ "${script}" != /* ]]
then
  # Make relative path absolute.
  script=$(pwd)/$0
fi

parent="$(dirname ${script})/.."
echo $parent

loops=1

while [ $# -gt 0 ]
do
  case "$1" in

    --loops)
      shift
      if [ $# -gt 0 ]
      then
         loops=$1
         shift
      fi
      ;;

    *)
      echo "Unknown option $1"
      exit 1
      ;;
  esac
done

mkdir -p "${HOME}/tmp/cmsis-plus-tests"
tmp="${HOME}/tmp/cmsis-plus-tests"

cd "${parent}"
name="$(basename $(pwd))"

list=( "test-cmsis-rtos-valid-release" "test-cmsis-rtos-valid-debug" )

for f in "${list[@]}"
do
    (cd $f; make all)
done

rm -rf "${tmp}/${name}"

#/Users/ilg/Work/qemu/build/osx/qemu/gnuarmeclipse-softmmu/qemu-system-gnuarmeclipse --verbose --board STM32F4-Discovery --mcu STM32F407VG --gdb tcp::1234 -d unimp,guest_errors --semihosting-config enable=on,target=native --semihosting-cmdline validator

cnt=0
while [ $cnt -lt $loops ]
do
  for f in "${list[@]}"
  do
	# run executable
    qemu-system-gnuarmeclipse \
    --verbose --board STM32F4-Discovery --image $f/$f.elf  \
    -d unimp,guest_errors --semihosting-config enable=on,target=native --semihosting-cmdline validator
  done
    
  date >>"${tmp}/${name}"
  
  let cnt=cnt+1
done

echo
echo "${loops} x '${name}' PASSED"
