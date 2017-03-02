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
# echo ${parent}

if [ ${USER} == "ilg" ]
then
  # Use a custom hoembrew with extra compilers.
  export PATH=${HOME}/opt/homebrew-gcc/bin:${PATH}
else
  echo "Be sure that gcc-[56] and clang-3.8 are in the PATH."
fi

bash "${parent}/run-travis.sh"

say "Wake up, the test completed successfully"
