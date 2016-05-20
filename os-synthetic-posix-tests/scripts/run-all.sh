#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

list=( \
"test-cmsis-rtos-valid-clang-release" \
"test-cmsis-rtos-valid-clang-debug" \
"test-cmsis-rtos-valid-gcc-release" \
"test-cmsis-rtos-valid-gcc-debug" \
"test-mutex-stress-clang-release" \
"test-mutex-stress-gcc-release" \
"test-templates-gcc-debug" \
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

for f in "${list[@]}"
do
    echo make $f
    (cd $f; make all)
done

rm -rf "${tmp}/${name}"

cnt=0
while [ $cnt -lt $loops ]
do
  for f in "${list[@]}"
  do
	# run executable
    $f/$f
  done

  date >>"${tmp}/${name}"

  let cnt=cnt+1
done

echo
echo "${loops} x '${name}' PASSED"
