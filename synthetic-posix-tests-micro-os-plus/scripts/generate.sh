#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# Until the xPacks utilities will be functional, use this Bash script
# to generate the project folders from the xPacks repository.
# -----------------------------------------------------------------------------

# Prefer the environment location XPACKS_REPO_FOLDER, if defined.

xpacks_paths_helper_path="${HOME}/Downloads/xpacks-paths.sh"

# Check if the helper is present.
if [ ! -f "${xpacks_paths_helper_path}" ]
then
  mkdir -p "${HOME}/Downloads"
  echo "Downloading xpacks-paths.sh..."
  curl -L https://github.com/xpacks/scripts/raw/master/xpacks-paths.sh -o "${xpacks_paths_helper_path}"
fi

source  "${xpacks_paths_helper_path}"

# -----------------------------------------------------------------------------

# Process command line options.
do_process_args $@

# Print greeting.
do_greet

# Check dependencies; clone if not found.
# do_install_xpack "arm-cmsis" "ilg" "https://github.com/xpacks/arm-cmsis.git"
do_install_xpack "micro-os-plus-iii" "ilg" "https://github.com/micro-os-plus/micro-os-plus-iii.git"
do_install_xpack "micro-os-plus-iii-cortexm" "ilg" "https://github.com/micro-os-plus/micro-os-plus-iii-cortexm.git"
do_install_xpack "arm-cmsis-rtos-validator" "ilg" "https://github.com/xpacks/arm-cmsis-rtos-validator.git"
do_install_xpack "posix-arch" "ilg" "https://github.com/micro-os-plus/posix-arch.git"

do_install_xpack "chan-fatfs" "ilg" "https://github.com/xpacks/chan-fatfs.git"

# Recreate the destination folder.
do_remove_dest
do_create_dest

# Add the 'arm-cmsis' xPack.
# do_add_arm_cmsis_xpack driver

# Add the 'micro-os-plus-iii' xPack.
do_add_micro_os_plus_iii_xpack posix-io
do_add_micro_os_plus_iii_tests_xpack rtos mutex-stress sema-stress

# Add the 'posix-arch' xPack.
do_add_posix_arch_xpack

# Add the 'arm-cmsis-rtos-validator' xPack
do_add_arm_cmsis_rtos_validator_xpack

do_add_chan_fatfs_xpack

# Change file modes to read/only.
do_protect

# List result.
do_list

do_done
