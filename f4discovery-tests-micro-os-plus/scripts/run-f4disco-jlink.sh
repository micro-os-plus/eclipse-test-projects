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

list=( "test-stress-sema-release" )

for f in "${list[@]}"
do
    (cd $f; make all)
done

rm -rf "${tmp}/${name}"

for f in "${list[@]}"
do

  # write flash
  rm -rf "${tmp}/jlink.script"
  echo "speed auto" >>"${tmp}/jlink.script"
  echo "loadfile $f/$f.hex" >>"${tmp}/jlink.script"
  echo "exit" >>"${tmp}/jlink.script"
  JLinkExe -device STM32F407VG -if swd -speed 1000 -CommanderScript "${tmp}/jlink.script"
  
  echo "$f flashed"
  echo "$f flashed" >>"${tmp}/${name}"
  
  cnt=0
  while [ $cnt -lt $loops ]
  do
	# run the test
    rm -rf "${tmp}/jlinkgdbserver.script"
    echo "speed auto" >>"${tmp}/jlinkgdbserver.script"
    echo "reset" >>"${tmp}/jlinkgdbserver.script"
    echo "semihosting enable" >>"${tmp}/jlinkgdbserver.script"
    echo "semihosting breakOnError" >>"${tmp}/jlinkgdbserver.script"
    echo "semihosting IOclient 3" >>"${tmp}/jlinkgdbserver.script"    
    echo "setargs arg0 arg1 arg2" >>"${tmp}/jlinkgdbserver.script"
    echo "go" >>"${tmp}/jlinkgdbserver.script"
    
	JLinkGDBServer \
	-if swd -device STM32F407VG -endian little -speed 1000 \
	-ir -halt -strict -timeout 0 -nogui -localhostonly \
	-scriptfile "${tmp}/jlinkgdbserver.script"
	    
    date >>"${tmp}/${name}"
  
    let cnt=cnt+1
  done
done

echo
echo "${loops} x '${name}' PASSED"
