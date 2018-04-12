#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

list_short=( \
"test-cmsis-rtos-valid-clang-release" \
"test-cmsis-rtos-valid-gcc7-release" \
"test-rtos-clang-release" \
"test-rtos-gcc7-release" \
"test-mutex-stress-clang-release" \
"test-mutex-stress-gcc7-release" \
\
"test-cmsis-rtos-valid-clang-debug" \
"test-cmsis-rtos-valid-gcc7-debug" \
"test-rtos-clang-debug" \
"test-rtos-gcc7-debug" \
)

list_all=( \
"test-cmsis-rtos-valid-clang-release" \
"test-cmsis-rtos-valid-gcc-release" \
"test-cmsis-rtos-valid-gcc6-release" \
"test-cmsis-rtos-valid-gcc7-release" \
"test-rtos-clang-release" \
"test-rtos-gcc-release" \
"test-rtos-gcc6-release" \
"test-rtos-gcc7-release" \
"test-mutex-stress-clang-release" \
"test-mutex-stress-gcc-release" \
"test-mutex-stress-gcc6-release" \
"test-mutex-stress-gcc7-release" \
\
"test-cmsis-rtos-valid-clang-debug" \
"test-cmsis-rtos-valid-gcc-debug" \
"test-cmsis-rtos-valid-gcc6-debug" \
"test-cmsis-rtos-valid-gcc7-debug" \
"test-rtos-clang-debug" \
"test-rtos-gcc-debug" \
"test-rtos-gcc6-debug" \
"test-rtos-gcc7-debug" \
)

script=$0
if [[ "${script}" != /* ]]
then
  # Make relative path absolute.
  script=$(pwd)/$0
fi

parent="$(dirname ${script})/.."
echo $parent

loops=1

list=("${list_short[@]}")

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
    --all)
      shift
      list=("${list_all[@]}")
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

for f in "${list[@]}"
do
    echo
    echo make $f
    (cd $f; make all)
done

rm -rf "${tmp}/${name}"

cnt=0
while [ $cnt -lt $loops ]
do
  for f in "${list[@]}"
  do
    echo
    echo run $f
	  # run executable
    $f/$f
  done

  date >>"${tmp}/${name}"

  let cnt=cnt+1
done

echo
echo "${loops} x '${name}' PASSED"
