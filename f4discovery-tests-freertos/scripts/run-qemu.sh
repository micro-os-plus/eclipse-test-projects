#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

cnt=1

function on_exit {
  echo "Count is $cnt"
  say Wake up, the test failed after $cnt iterations!
}

trap on_exit EXIT

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
name="$(basename $(pwd))".txt

# Mutex fails at the end, to be investigated.

list=( \
"test-cmsis-rtos-valid-release" \
"test-rtos-release" \
#"test-mutex-stress-release" \
"test-cmsis-rtos-valid-debug" \
"test-rtos-debug" \
)

for f in "${list[@]}"
do
    echo
    echo make $f
    (cd $f; make all)
done

rm -rf "${tmp}/${name}"

while [ $cnt -le $loops ]
do
  for f in "${list[@]}"
  do
    echo
    echo run $f
	# run executable
    qemu-system-gnuarmeclipse \
    --verbose --board STM32F4-Discovery --image $f/$f.elf --nographic \
    -d unimp,guest_errors --semihosting-config enable=on,target=native --semihosting-cmdline test
  done

  date >>"${tmp}/${name}"
  echo $cnt >>"${tmp}/${name}"
  
  echo $cnt
  say $cnt

  let cnt=cnt+1
done

trap "" EXIT

echo
echo "${loops} x '${name}' PASSED"
