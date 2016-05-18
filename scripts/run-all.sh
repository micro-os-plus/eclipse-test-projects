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
# echo $parent

bash "${parent}/os-synthetic-posix-tests/scripts/run-all.sh" --loop 5

echo
echo "All PASSED"
echo
