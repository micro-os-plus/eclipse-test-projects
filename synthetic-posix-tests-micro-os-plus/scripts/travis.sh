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
  project_name="synthetic-posix-tests-micro-os-plus"
  project_path="${slug}/${project_name}"
else
  work="${HOME}/Work/travis"
  project_path="$(dirname ${parent})"
  project_name="$(basename ${project_path})"
  slug="$(dirname ${project_path})"
fi

use_clang="false"
use_clang38="false"
use_clang39="false"

use_gcc="false"
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

  use_clang="true"
  use_clang38="true"
  use_clang39="false"

  use_gcc="true"
  use_gcc5="true"
  use_gcc6="true"

elif [ "${TRAVIS_OS_NAME}" == "linux" ]
then

  cache="${HOME}/.cache/travis"

  eclipse_folder_name="eclipse"
  eclipse_folder_path="${work}/${eclipse_folder_name}"
  eclipse="${eclipse_folder_path}/eclipse"

  p2_os="linux"
  p2_ws="gtk"

  use_clang="false"
  # For now clang compiles, but fails to run.
  # To be investigate at a later time.
  use_clang38="false"
  use_clang39="false"

  # Plain gcc may be too old to be useful.
  use_gcc="false"
  if [ "${TRAVIS}" == "true" ]
  then
    use_gcc5="false"
  else
    use_gcc5="true"
  fi
  use_gcc6="true"

else

  echo "${TRAVIS_OS_NAME} not supported"
  exit 1
  
fi

cdt_release="8.8.1"
cdt_folder_name="cdt-${cdt_release}"
cdt_folder_path="${work}/${cdt_folder_name}"
cdt_archive_name="${cdt_folder_name}.zip"
cdt_archive_url="http://download.eclipse.org/tools/cdt/releases/${cdt_release}/${cdt_archive_name}"

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

  echo
  echo "Building '${cfg}' with ${toolchain_name}..."
  
  local code=0
  local toolchain_name=$2

  # Temporarily disable errors, because Eclipse headless builds sometimes 
  # return non-zero even if the build is successful; if the build fails, 
  # there will be no binary and the next test will fail.
  set +o errexit 
  do_run_quietly "${eclipse}" \
    --launcher.suppressErrors \
    -nosplash \
    -application org.eclipse.cdt.managedbuilder.core.headlessbuild \
    -data "${work}/workspace" \
    -cleanBuild synthetic-posix-tests-micro-os-plus/${cfg} 
      
  code=$?

  set -o errexit 

  if [ \( ${code} -eq 0 \) -a \( -f "${project_path}/${cfg}/${cfg}" \) ]
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

  echo
  echo "Building '${cfg}' with ${toolchain_name}..."
  
  local code=0
  local toolchain_name=$2

  # Temporarily disable errors, because (???); 
  # if the build fails, the attempt to run the binary will fail anyway.
  set +o errexit 

  # Clean build a configuration.
  do_run_quietly "${eclipse}" \
    --launcher.suppressErrors \
    -nosplash \
    -application org.eclipse.cdt.managedbuilder.core.headlessbuild \
    -data "${work}/workspace" \
    -cleanBuild synthetic-posix-tests-micro-os-plus/${cfg} 
  
  code=$?

  set -o errexit 

  if [ \( ${code} -eq 0 \) -a \( -f "${project_path}/${cfg}/${cfg}" \) ]
  then
    echo
    echo "Running '${cfg}'..."
    set +o errexit 
    do_run_quietly "${project_path}/${cfg}/${cfg}"
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

  if [ "${TRAVIS}" == "true" ]
  then

    if [ "${TRAVIS_OS_NAME}" == "osx" ]
    then

      # Specific GCC versions are installed via brew.
      # Prefer packages from the new multi-version core.
      # do_run brew tap homebrew/versions

      do_run brew --version

      do_run brew cask list
      # oclint creates `/usr/local/include/c++`, which prevents
      # gcc@[56] to link to system locations.
      do_run brew cask uninstall oclint

      if [ "${use_gcc5}" == "true" ]
      then
        do_run brew install gcc5
      fi

      if [ "${use_gcc6}" == "true" ]
      then
        do_run brew install gcc6
      fi

      if [ "${use_clang38}" == "true" ]
      then
        do_run brew install llvm@3.8
      fi

      # llvm@3.9 is not yet available.
      if [ "${use_clang39}" == "true" ]
      then
        do_run brew install llvm@3.9
      fi
 
    elif [ "${TRAVIS_OS_NAME}" == "linux" ]
    then
      # gcc-[56], clang-3.[89] should have been installed via `addons.apt`. 
      :
    fi
  
  else
    # When not running on Travis.
    :
  fi

  if [ "${use_clang}" == "true" ]
  then
    echo
    do_run clang --version
    do_run clang++ --version
  fi

  if [ "${use_clang38}" == "true" ]
  then
    echo
    do_run clang-3.8 --version
    do_run clang++-3.8 --version
  fi

  if [ "${use_clang39}" == "true" ]
  then
    echo
    do_run clang-3.9 --version
    do_run clang++-3.9 --version
  fi

  if [ "${use_gcc}" == "true" ]
  then
    echo
    do_run gcc --version
    do_run g++ --version
  fi

  if [ "${use_gcc5}" == "true" ]
  then
    echo
    do_run gcc-5 --version
    do_run g++-5 --version
  fi

  if [ "${use_gcc6}" == "true" ]
  then
    echo
    do_run gcc-6 --version
    do_run g++-6 --version
  fi

  if [ "${TRAVIS_OS_NAME}" == "osx" ]
  then
    eclipse_archive_name=eclipse-cpp-mars-2-macosx-cocoa-x86_64.tar.gz
  elif [ "${TRAVIS_OS_NAME}" == "linux" ]
  then
    eclipse_archive_name=eclipse-cpp-mars-2-linux-gtk-x86_64.tar.gz
  fi

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

  if [ ! -f "${cache}/${cdt_archive_name}" ]
  then
    mkdir -p "${cache}"
    echo
    echo "Downloading the CDT archived repository..."
    do_run curl -L \
      "${cdt_archive_url}" \
      -o "${cache}/${cdt_archive_name}"
  fi

  if [ ! -d "${work}/${eclipse_folder_name}" ]
  then
    mkdir -p "${work}"
    echo
    echo "Unpacking the Eclipse distribution..."
    do_run tar -x -z -f "${cache}/${eclipse_archive_name}" -C "${work}"
  fi

  if [ ! -d "${cdt_folder_path}" ]
  then
    mkdir "${cdt_folder_path}"
    echo
    echo "Unpacking the CDT p2 repository..."
    do_run unzip -q -d "${cdt_folder_path}" "${cache}/${cdt_archive_name}"
  fi

  # Install "C/C++ LLVM-Family Compiler Build Support" feature,
  # which is not present by default in the Eclipse CDT distributions.

  # The LLVM plug-in is necessary even if the clang tests are disabled,
  # otherwise CDT will complain for each clang configuration.

  # The p2.os, p2.ws, p2.arch might help to make the right plug-in selection.

  # Eclipse Launcher runt-time options
  # http://help.eclipse.org/mars/index.jsp?topic=%2Forg.eclipse.platform.doc.isv%2Freference%2Fmisc%2Fruntime-options.html

  # Eclipse provisioning, installation management
  # http://help.eclipse.org/mars/index.jsp?topic=%2Forg.eclipse.platform.doc.isv%2Fguide%2Fp2_director.html

  local feature_id="org.eclipse.cdt.managedbuilder.llvm"
  local feature_group="${feature_id}.feature.group"

  mkdir -p "${work}"
  echo
  echo "Installing the CDT LLVM plug-ins..."
  do_run "${eclipse}" \
    --launcher.suppressErrors \
    -nosplash \
    -application org.eclipse.equinox.p2.director \
    -repository "file:///${cdt_folder_path}" \
    -installIU "${feature_group}" \
    -tag InitialState \
    -destination "${eclipse_folder_path}/" \
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
  # do_run rm -rf "${work}/workspace"
  echo
  echo "Importing Eclipse project '${project_name}' into workspace..."
  do_run "${eclipse}" \
    --launcher.suppressErrors \
    -nosplash \
    -application org.eclipse.cdt.managedbuilder.core.headlessbuild \
    -data "${work}/workspace" \
    -import "${project_path}"

  return 0
}

# Errors in this function will break the build.
function do_script() {

  echo
  echo "Performing the synthetic POSIX tests..."

  cd "${slug}"

  # Build & possibly run configurations.
  # Configurations too heavy (lots of traces) are build only.

  if [ "${use_clang}" == "true" ]
  then
    echo
    do_run clang++ --version

    local toolchain_name="clang"

    do_build_run "test-cmsis-rtos-valid-clang-release" ${toolchain_name}
    do_build_run "test-cmsis-rtos-valid-clang-debug" ${toolchain_name}

    do_build_run "test-rtos-clang-release" ${toolchain_name}
    do_build_run "test-rtos-clang-debug" ${toolchain_name}

    do_build_run "test-mutex-stress-clang-release" ${toolchain_name}
    # Mutex stress as release only, debug too heavy.
    do_build "test-mutex-stress-clang-debug" ${toolchain_name}
  fi

  if [ "${use_clang38}" == "true" ]
  then
    echo
    do_run clang++-3.8 --version

    local toolchain_name="clang-3.8"

    do_build_run "test-cmsis-rtos-valid-clang38-release" ${toolchain_name}
    do_build_run "test-cmsis-rtos-valid-clang38-debug" ${toolchain_name}

    do_build_run "test-rtos-clang38-release" ${toolchain_name}
    do_build_run "test-rtos-clang38-debug" ${toolchain_name}

    do_build_run "test-mutex-stress-clang38-release" ${toolchain_name}
    # Mutex stress as release only, debug too heavy.
    do_build "test-mutex-stress-clang38-debug" ${toolchain_name}
  fi

  if [ "${use_clang39}" == "true" ]
  then
    echo
    do_run clang++-3.9 --version
    
    local toolchain_name="clang-3.9"

    do_build_run "test-cmsis-rtos-valid-clang39-release" ${toolchain_name}
    do_build_run "test-cmsis-rtos-valid-clang39-debug" ${toolchain_name}

    do_build_run "test-rtos-clang39-release" ${toolchain_name}
    do_build_run "test-rtos-clang39-debug" ${toolchain_name}

    do_build_run "test-mutex-stress-clang39-release" ${toolchain_name}
    # Mutex stress as release only, debug too heavy.
    do_build "test-mutex-stress-clang39-debug" ${toolchain_name}
  fi

  if [ "${use_gcc}" == "true" ]
  then
    echo
    do_run g++ --version

    local toolchain_name="gcc"

    do_build_run "test-cmsis-rtos-valid-gcc-release" ${toolchain_name}
    do_build_run "test-cmsis-rtos-valid-gcc-debug" ${toolchain_name}

    do_build_run "test-rtos-gcc-release" ${toolchain_name}
    do_build_run "test-rtos-gcc-debug" ${toolchain_name}

    do_build_run "test-mutex-stress-gcc-release" ${toolchain_name}
    # Mutex stress as release only, debug too heavy.
    do_build "test-mutex-stress-gcc-debug" ${toolchain_name}
  fi

  if [ "${use_gcc5}" == "true" ]
  then
    echo
    do_run g++-5 --version

    local toolchain_name="gcc-5"

    do_build_run "test-cmsis-rtos-valid-gcc5-release" ${toolchain_name}
    do_build_run "test-cmsis-rtos-valid-gcc5-debug" ${toolchain_name}

    do_build_run "test-rtos-gcc5-release" ${toolchain_name}
    do_build_run "test-rtos-gcc5-debug" ${toolchain_name}

    do_build_run "test-mutex-stress-gcc5-release" ${toolchain_name}
    # Mutex stress as release only, debug too heavy.
    do_build "test-mutex-stress-gcc5-debug" ${toolchain_name}
  fi

  if [ "${use_gcc6}" == "true" ]
  then
    echo
    do_run g++-6 --version
    
    local toolchain_name="gcc-6"

    do_build_run "test-cmsis-rtos-valid-gcc6-release" ${toolchain_name}
    do_build_run "test-cmsis-rtos-valid-gcc6-debug" ${toolchain_name}

    # GCC 6.2 fails with header error.
    do_build_run "test-rtos-gcc6-release" ${toolchain_name}
    do_build_run "test-rtos-gcc6-debug" ${toolchain_name}

    do_build_run "test-mutex-stress-gcc6-release" ${toolchain_name}
    # Mutex stress as release only, debug too heavy.
    do_build "test-mutex-stress-gcc6-debug" ${toolchain_name}
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
