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

for f in test-*
do
    (cd $f; make all)
done

rm -rf "${tmp}/${name}"

cnt=0
while [ $cnt -lt $loops ]
do
  for f in test-*
  do
	# run executable
    $f/$f
  done
    
  date >>"${tmp}/${name}"
  
  let cnt=cnt+1
done

echo
echo "${loops} x '${name}' PASSED"
