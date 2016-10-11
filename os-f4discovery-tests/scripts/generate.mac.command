#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Wrapper for macOS; execute it by double clicking in Finder.
# -----------------------------------------------------------------------------

script=$0
if [[ "${script}" != /* ]]
then
  # Make relative path absolute.
  script=$(pwd)/$0
fi

parent="$(dirname ${script})"

# -----------------------------------------------------------------------------

if [ "$USER" == "ilg" ]
then
  # For 'ilg' use the development tree.
  bash "$parent/generate.sh" --symlink
else
  bash "$parent/generate.sh"
fi

# -----------------------------------------------------------------------------
