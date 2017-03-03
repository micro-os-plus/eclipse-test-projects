#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# Safety settings (see https://gist.github.com/ilg-ul/383869cbb01f61a51c4d).

if [[ ! -z ${DEBUG} ]]
then
  set ${DEBUG} # Activate the expand mode if DEBUG is anything but empty.
else
  DEBUG=""
fi

set -o errexit # Exit if command failed.
set -o pipefail # Exit if pipe failed.
set -o nounset # Exit if variable not set.

# Remove the initial space and instead use '\n'.
IFS=$'\n\t'

# -----------------------------------------------------------------------------

script=$0
if [[ "${script}" != /* ]]
then
  # Make relative path absolute.
  script=$(pwd)/$0
fi

parent="$(dirname ${script})"
# echo $parent

# -----------------------------------------------------------------------------

# https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables

# For local build, provide 
# - TRAVIS=false
# - TRAVIS_OS_NAME=osx|linux

# - TRAVIS_REPO_SLUG=<user>/<repo>

if [ "${TRAVIS}" == "true" ]
then
  work="${HOME}"
  slug="${TRAVIS_BUILD_DIR}"
  project_name="f4discovery-tests-micro-os-plus"
  project_path="${slug}/${project_name}"
else
  work="${HOME}/Work/travis"
  project_path="$(dirname ${parent})"
  project_name="$(basename ${project_path})"
  slug="$(dirname ${project_path})"
fi

use_gcc5="false"
use_gcc6="false"

if [ "${TRAVIS_OS_NAME}" == "osx" ]
then

  cache="${HOME}/Library/Caches/Travis"

  eclipse_folder_name="Eclipse.app" 
  eclipse_folder_path="${work}/${eclipse_folder_name}"
  eclipse="${eclipse_folder_path}/Contents/MacOS/eclipse" 

  p2_os="macosx"
  p2_ws="cocoa"

  use_gcc5="true"
  use_gcc6="true"

  gcc5_archive_name="gcc-arm-none-eabi-5_4-2016q3-20160926-mac.tar.bz2"
  gcc5_url_base="https://launchpad.net/gcc-arm-embedded/5.0/5-2016-q3-update/+download"

  # https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads
  gcc6_archive_name="gcc-arm-none-eabi-6-2017-q1-update-mac.tar.bz2"
  gcc6_url_base="https://developer.arm.com/-/media/Files/downloads/gnu-rm/6-2017q1"

  # https://github.com/gnuarmeclipse/qemu/releases
  # https://github.com/gnuarmeclipse/qemu/releases/download/gae-2.8.0-20170301/gnuarmeclipse-qemu-osx-2.8.0-201703012029-head.tgz
  qemu_archive_name="gnuarmeclipse-qemu-osx-2.8.0-201703012029-head.tgz"
  qemu_url_base="https://github.com/gnuarmeclipse/qemu/releases/download/gae-2.8.0-20170301"
  qemu_folder_name="gnuarmeclipse/qemu/2.8.0-201703012029-head"

  eclipse_archive_name=eclipse-cpp-mars-2-macosx-cocoa-x86_64.tar.gz

elif [ "${TRAVIS_OS_NAME}" == "linux" ]
then

  cache="${HOME}/.cache/travis"

  eclipse_folder_name="eclipse"
  eclipse_folder_path="${work}/${eclipse_folder_name}"
  eclipse="${eclipse_folder_path}/eclipse"

  p2_os="linux"
  p2_ws="gtk"

  # sudo apt-get install lib32ncurses5

  if [ "${TRAVIS}" == "true" ]
  then
    use_gcc5="false"
  else
    use_gcc5="true"
  fi
  use_gcc6="true"

  # https://launchpad.net/gcc-arm-embedded/5.0/5-2016-q3-update/+download/gcc-arm-none-eabi-5_4-2016q3-20160926-linux.tar.bz2
  gcc5_archive_name="gcc-arm-none-eabi-5_4-2016q3-20160926-linux.tar.bz2"
  gcc5_url_base="https://launchpad.net/gcc-arm-embedded/5.0/5-2016-q3-update/+download"

  # https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads
  # https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/6_1-2017q1/gcc-arm-none-eabi-6-2017-q1-update-linux.tar.bz2
  gcc6_archive_name="gcc-arm-none-eabi-6-2017-q1-update-linux.tar.bz2"
  gcc6_url_base="https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/6_1-2017q1"

  # https://github.com/gnuarmeclipse/qemu/releases
  # https://github.com/gnuarmeclipse/qemu/releases/download/gae-2.8.0-20170301/gnuarmeclipse-qemu-debian64-2.8.0-201703022210-head.tgz
  qemu_archive_name="gnuarmeclipse-qemu-debian64-2.8.0-201703022210-head.tgz"
  qemu_url_base="https://github.com/gnuarmeclipse/qemu/releases/download/gae-2.8.0-20170301"
  qemu_folder_name="gnuarmeclipse/qemu/2.8.0-201703022210-head"

  eclipse_archive_name=eclipse-cpp-mars-2-linux-gtk-x86_64.tar.gz

else

  echo "${TRAVIS_OS_NAME} not supported"
  exit 1
  
fi

eclipse_workspace_path="${work}/workspace-${project_name}"

gcc5_folder_name="gcc-arm-none-eabi-5_4-2016q3"
gcc5_folder_path="${work}/${gcc5_folder_name}"

gcc6_folder_name="gcc-arm-none-eabi-6-2017-q1-update"
gcc6_folder_path="${work}/${gcc6_folder_name}"

qemu_folder_path="${work}/${qemu_folder_name}"

gae_release="3.3.1-201702251311"
gae_folder_name="ilg.gnuarmeclipse.repository-${gae_release}"
gae_archive_name="${gae_folder_name}.zip"
gae_archive_url="https://github.com/gnuarmeclipse/plug-ins/releases/download/v${gae_release}/${gae_archive_name}"
gae_folder_path="${work}/${gae_folder_name}"

mkdir -p "${cache}"

saved_path=${PATH}

# -----------------------------------------------------------------------------

function do_run()
{
  echo "\$ $@"
  "$@"
}

function do_run_quietly()
{
  echo "\$ $@ > output.log"
  "$@" > "${work}/output.log"
}

# $1 configuration name
# $2 toolchain name
function do_build()
{
  local cfg=$1
  local toolchain_name=$2

  echo
  echo "Building '${cfg}' with ${toolchain_name}..."
  
  local code=0

  # Temporarily disable errors, because Eclipse headless builds sometimes 
  # return non-zero even if the build is successful; if the build fails, 
  # there will be no binary and the next test will fail.
  set +o errexit 
  do_run_quietly "${eclipse}" \
    --launcher.suppressErrors \
    -nosplash \
    -application org.eclipse.cdt.managedbuilder.core.headlessbuild \
    -data "${eclipse_workspace_path}" \
    -cleanBuild "${project_name}/${cfg}" 
      
  code=$?

  set -o errexit 

  if [ -f "${project_path}/${cfg}/${cfg}.elf" ]
  then
    echo
    echo "'${cfg}' passed."
    return 0
  fi

  if [ -f "${work}/output.log" ]
  then
    cat "${work}/output.log"
  fi

  echo
  echo "'${cfg}' FAILED"

  return ${code}
}

# $1 configuration name
# $2 toolchain name
function do_build_run()
{
  local cfg=$1
  local toolchain_name=$2

  echo
  echo "Building '${cfg}' with ${toolchain_name}..."
  
  local code=0
  local board_name="STM32F4-Discovery"

  # Temporarily disable errors, because (???); 
  # if the build fails, the attempt to run the binary will fail anyway.
  set +o errexit 

  # Clean build a configuration.
  do_run_quietly "${eclipse}" \
    --launcher.suppressErrors \
    -nosplash \
    -application org.eclipse.cdt.managedbuilder.core.headlessbuild \
    -data "${eclipse_workspace_path}" \
    -cleanBuild "${project_name}/${cfg}" 
  
  code=$?

  set -o errexit 

  if [ -f "${project_path}/${cfg}/${cfg}.elf" ]
  then
    echo
    echo "Running '${cfg}' with QEMU ${board_name}..."
    set +o errexit 
    do_run_quietly ${qemu_folder_path}/bin/qemu-system-gnuarmeclipse \
      --image "${project_path}/${cfg}/${cfg}.elf" \
      --board "${board_name}" \
      --nographic \
      --verbose \
      -d unimp,guest_errors \
      --semihosting-config enable=on,target=native \
      --semihosting-cmdline test
    code=$?
    set -o errexit 

    if [ ${code} -eq 0 ]
    then
      echo
      echo "'${cfg}' passed."
      return 0
    fi
  fi

  if [ \( ${code} -ne 0 \) -a \( -f "${work}/output.log" \) ]
  then
    cat "${work}/output.log"
  fi

  if [ ${code} -ne 0 ]
  then
    echo
    echo "'${cfg}' FAILED"
  fi

  echo
  echo "'${cfg}' passed."
  return 0
}

# -----------------------------------------------------------------------------

# Errors in this function will break the build.
function do_before_install() {

  echo
  echo "Before install; bringing in extra tools..."

  # ---------------------------------------------------------------------------

  if [ "${use_gcc5}" == "true" ]
  then

    if [ ! -f "${cache}/${gcc5_archive_name}" ]
    then
      gcc5_url="${gcc5_url_base}/${gcc5_archive_name}"
      mkdir -p "${cache}"
      echo
      echo "Downloading arm-none-eabi-gcc v5..."
      do_run curl -L ${gcc5_url} -o "${cache}/${gcc5_archive_name}"
    fi

    if [ ! -d "${gcc5_folder_path}" ]
    then
      mkdir -p "$(dirname ${gcc5_folder_path})"
      echo
      echo "Installing arm-none-eabi-gcc v5..."
      do_run tar -x -j -f "${cache}/${gcc5_archive_name}" -C "$(dirname ${gcc5_folder_path})"
    fi

    PATH="${gcc5_folder_path}/bin":${saved_path}
    do_run arm-none-eabi-gcc --version
    do_run arm-none-eabi-g++ --version
    PATH=${saved_path}

  fi

  # ---------------------------------------------------------------------------

  if [ "${use_gcc6}" == "true" ]
  then

    if [ ! -f "${cache}/${gcc6_archive_name}" ]
    then
      gcc6_url="${gcc6_url_base}/${gcc6_archive_name}"
      mkdir -p "${cache}"
      echo
      echo "Downloading arm-none-eabi-gcc v6..."
      do_run curl -L ${gcc6_url} -o "${cache}/${gcc6_archive_name}"
    fi

    if [ ! -d "${gcc6_folder_path}" ]
    then
      mkdir -p "$(dirname ${gcc6_folder_path})"
      echo
      echo "Installing arm-none-eabi-gcc v6..."
      do_run tar -x -j -f "${cache}/${gcc6_archive_name}" -C "$(dirname ${gcc6_folder_path})"
    fi

    PATH="${gcc6_folder_path}/bin":${saved_path}
    do_run arm-none-eabi-gcc --version
    do_run arm-none-eabi-g++ --version
    PATH=${saved_path}

  fi

  # ---------------------------------------------------------------------------

  if [ ! -f "${cache}/${qemu_archive_name}" ]
  then
    qemu_url="${qemu_url_base}/${qemu_archive_name}"
    mkdir -p "${cache}"
    echo
    echo "Downloading GNU ARM Eclipse QEMU..."
    do_run curl -L ${qemu_url} -o "${cache}/${qemu_archive_name}"
  fi

  if [ ! -d "${qemu_folder_path}" ]
  then
    mkdir -p "$(dirname $(dirname $(dirname ${qemu_folder_path})))"
    echo
    echo "Installing GNU ARM Eclipse QEMU..."
    do_run tar -x -z -f "${cache}/${qemu_archive_name}" -C "$(dirname $(dirname $(dirname ${qemu_folder_path})))"
  fi

  echo
  do_run "${qemu_folder_path}/bin/qemu-system-gnuarmeclipse" --version
  echo

  # ---------------------------------------------------------------------------

  eclipse_url="http://artfiles.org/eclipse.org//technology/epp/downloads/release/mars/2/${eclipse_archive_name}"

  if [ ! -f "${cache}/${eclipse_archive_name}" ]
  then
    mkdir -p "${cache}"
    echo
    echo "Downloading the large Eclipse distribution..."
    do_run curl -L \
      "${eclipse_url}" \
      -o "${cache}/${eclipse_archive_name}"
  fi

  if [ ! -f "${cache}/${gae_archive_name}" ]
  then
    mkdir -p "${cache}"
    echo
    echo "Downloading the GNU ARM Eclipse plug-ins archived repository..."
    do_run curl -L \
      "${gae_archive_url}" \
      -o "${cache}/${gae_archive_name}"
  fi

  if [ ! -d "${work}/${eclipse_folder_name}" ]
  then
    mkdir -p "${work}"
    echo
    echo "Unpacking the Eclipse distribution..."
    do_run tar -x -z -f "${cache}/${eclipse_archive_name}" -C "${work}"
  fi

  if [ ! -d "${gae_folder_path}" ]
  then
    mkdir -p "${gae_folder_path}"
    echo
    echo "Unpacking the GNU ARM Eclipse plug-ins p2 repository..."
    do_run unzip -q -d "${gae_folder_path}" "${cache}/${gae_archive_name}"
  fi

  # Install "GNU ARM Eclipse" plug-ins.
  # The p2.os, p2.ws, p2.arch might help to make the right plug-in selection.

  # Eclipse Launcher runt-time options
  # http://help.eclipse.org/mars/index.jsp?topic=%2Forg.eclipse.platform.doc.isv%2Freference%2Fmisc%2Fruntime-options.html

  # Eclipse provisioning, installation management
  # http://help.eclipse.org/mars/index.jsp?topic=%2Forg.eclipse.platform.doc.isv%2Fguide%2Fp2_director.html

  local feature_id="ilg.gnuarmeclipse.managedbuild.cross"
  local feature_group="${feature_id}.feature.group"

  mkdir -p "${work}"
  echo
  echo "Installing the GNU ARM Eclipse plug-ins..."
  do_run "${eclipse}" \
    --launcher.suppressErrors \
    -nosplash \
    -application org.eclipse.equinox.p2.director \
    -repository "file:///${gae_folder_path}" \
    -installIU "${feature_group}" \
    -tag InitialState \
    -destination "${work}/${eclipse_folder_name}/" \
    -profileProperties org.eclipse.update.install.features=true \
    -p2.os "${p2_os}" \
    -p2.ws "${p2_ws}" \
    -p2.arch x86_64 \
    -roaming 

  echo
  do_run ls -lL "${work}"

  return 0
}

# Errors in this function will break the build.
function do_before_script() {

  echo
  echo "Before starting the tests..."

  # Generate the required folders in the project, from downloaded xPacks. 
  cd "${project_path}"
  echo
  echo "Downloading the xPacks and generating the project sources..."
  do_run bash scripts/generate.sh "$@"

  # The project is now complete. Import it into the Eclipse workspace.
  # do_run rm -rf "${eclipse_workspace_path}"
  echo
  echo "Importing Eclipse project '${project_name}' into workspace..."
  do_run "${eclipse}" \
    --launcher.suppressErrors \
    -nosplash \
    -application org.eclipse.cdt.managedbuilder.core.headlessbuild \
    -data "${eclipse_workspace_path}" \
    -import "${project_path}"

  return 0
}

# Errors in this function will break the build.
function do_script() {

  echo
  echo "Performing the F4DISCOVERY µOS++ tests..."

  cd "${slug}"

  # Build & possibly run configurations.
  # Configurations too heavy (lots of traces) are build only.

  if [ "${use_gcc5}" == "true" ]
  then
    PATH="${gcc5_folder_path}/bin":${saved_path}

    echo
    do_run arm-none-eabi-g++ --version

    local toolchain_name="arm-none-eabi-gcc v5"

    do_build_run "test-cmsis-rtos-valid-release" ${toolchain_name}
    do_build_run "test-cmsis-rtos-valid-debug" ${toolchain_name}

    do_build_run "test-rtos-release" ${toolchain_name}
    do_build_run "test-rtos-debug" ${toolchain_name}

    do_build_run "test-mutex-stress-release" ${toolchain_name}
    # Mutex stress as release only, debug too heavy.
    do_build "test-mutex-stress-debug" ${toolchain_name}

    # Semaphore stress build only, does not run on QEMU (yet).
    do_build "test-sema-stress-release" ${toolchain_name}
    do_build "test-sema-stress-debug" ${toolchain_name}

    PATH=${saved_path}
  fi

  if [ "${use_gcc6}" == "true" ]
  then
    PATH="${gcc6_folder_path}/bin":${saved_path}

    echo
    do_run arm-none-eabi-g++ --version

    local toolchain_name="arm-none-eabi-gcc v6"

    do_build_run "test-cmsis-rtos-valid-release" ${toolchain_name}
    do_build_run "test-cmsis-rtos-valid-debug" ${toolchain_name}

    do_build_run "test-rtos-release" ${toolchain_name}
    do_build_run "test-rtos-debug" ${toolchain_name}

    do_build_run "test-mutex-stress-release" ${toolchain_name}
    # Mutex stress as release only, debug too heavy.
    do_build "test-mutex-stress-debug" ${toolchain_name}

    # Semaphore stress build only, does not run on QEMU (yet).
    do_build "test-sema-stress-release" ${toolchain_name}
    do_build "test-sema-stress-debug" ${toolchain_name}

    PATH=${saved_path}
  fi

  echo
  echo "PASSED"
  return 0
}

# Errors in the following function will not break the build.

function do_after_success() {

  echo "Nothing to do after success..."
  return 0
}

function do_after_failure() {

  echo "Nothing to do after failure..."
  return 0
}

function do_deploy() {

  echo "Nothing to do to deploy..."
  return 0
}

function do_after_script() {

  echo "Nothing to do after script..."
  return 0
}

# -----------------------------------------------------------------------------

# https://docs.travis-ci.com/user/customizing-the-build/#The-Build-Lifecycle

# - OPTIONAL Install apt addons
# - OPTIONAL Install cache components
# - before_install
# - install
# - before_script
# - script
# - OPTIONAL before_cache (for cleaning up cache)
# - after_success or after_failure
# - OPTIONAL before_deploy
# - OPTIONAL deploy
# - OPTIONAL after_deploy
# - after_script

if [ $# -ge 1 ]
then
  action=$1
  shift

  case ${action} in

  before_install)
    do_before_install "$@"
    ;;

  before_script)
    do_before_script "$@"
    ;;

  script)
    do_script "$@"
    ;;

  after_success)
    do_after_success "$@"
    ;;

  after_failure)
    do_after_failure "$@"
    ;;

  deploy)
    do_deploy "$@"
    ;;

  after_script)
    do_after_script "$@"
    ;;

  *)
    echo "Unsupported command" "${action}" "$@"
    exit 1
    ;;
    
  esac
  exit 0
else
  echo "Missing command"
  exit 1
fi

# -----------------------------------------------------------------------------
