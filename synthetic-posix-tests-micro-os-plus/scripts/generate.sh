#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Until the xPacks utilities will be functional, use this Bash script
# to generate the project folders from the xPacks repository.
# -----------------------------------------------------------------------------

# Prefer the environment location XPACKS_REPO_FOLDER, if defined.

xpacks_paths_helper="${HOME}/Downloads/xpacks-paths.sh"

# Check if the helper is present.
if [ ! -f "${xpacks_paths_helper}" ]
then
  mkdir -p "${HOME}/Downloads"
  echo "Downloading bootstrap-paths.sh..."
  curl -L https://github.com/xpacks/scripts/raw/master/xpacks-paths.sh -o "${xpacks_paths_helper}"
fi

source  "${xpacks_paths_helper}"

# -----------------------------------------------------------------------------

# Check if the helper is present.
if [ ! -f "${xpacks_repo_folder}/ilg/scripts.git/xpacks-helper.sh" ]
then
  mkdir -p "${HOME}/Downloads"
  echo "Downloading bootstrap.sh..."
  # curl -L https://github.com/xpacks/scripts/raw/master/bootstrap.sh -o "${HOME}/Downloads/bootstrap.sh"
  bash  "${HOME}/Downloads/bootstrap.sh"
fi

# -----------------------------------------------------------------------------

helper_script="$xpacks_repo_folder/ilg/scripts.git/xpacks-helper.sh"

# Include common definitions from helper script.
source "${helper_script}"

# -----------------------------------------------------------------------------

# Get the full absolute path of the current script.
script=$0
if [[ "${script}" != /* ]]
then
  # Make relative path absolute.
  script=$(pwd)/$0
fi

# -----------------------------------------------------------------------------

# Process command line options.
do_process_args $@

# Print greeting.
do_greet

# Check dependencies; clone if not found.
do_install_xpack "arm-cmsis" "ilg" "https://github.com/xpacks/arm-cmsis.git"
do_install_xpack "micro-os-plus-iii" "ilg" "https://github.com/micro-os-plus/micro-os-plus-iii.git"
do_install_xpack "micro-os-plus-iii-cortexm" "ilg" "https://github.com/micro-os-plus/micro-os-plus-iii-cortexm.git"
do_install_xpack "arm-cmsis-rtos-validator" "ilg" "https://github.com/xpacks/arm-cmsis-rtos-validator.git"
do_install_xpack "posix-arch" "ilg" "https://github.com/micro-os-plus/posix-arch.git"


# Recreate the destination folder.
do_remove_dest
do_create_dest

# Add the 'arm-cmsis' xPack.
do_add_arm_cmsis_xpack driver

# Add the 'micro-os-plus-iii' xPack.
do_add_micro_os_plus_iii_xpack 
do_add_micro_os_plus_iii_tests_xpack rtos mutex-stress sema-stress

# Add the 'posix-arch' xPack.
do_add_posix_arch_xpack

# Add the 'arm-cmsis-rtos-validator' xPack
do_add_arm_cmsis_rtos_validator_xpack

# Change file modes to read/only.
do_protect

# List result.
do_list

do_done
