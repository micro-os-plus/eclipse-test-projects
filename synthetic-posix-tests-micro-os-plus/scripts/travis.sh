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
  project="${slug}/synthetic-posix-tests-micro-os-plus"
else
  work="${HOME}/Work/travis"
  project="$(dirname ${parent})"
  slug="$(dirname ${project})"
fi

if [ "${TRAVIS_OS_NAME}" == "osx" ]
then
  cache="${HOME}/Library/Caches/Travis"
  eclipse="${work}/Eclipse.app/Contents/MacOS/eclipse" 
elif [ "${TRAVIS_OS_NAME}" == "linux" ]
then
  cache="${HOME}/.cache/travis"
  eclipse="${work}/eclipse/eclipse"
fi

mkdir -p "${cache}"

export work
export slug
export cache
export project

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

# -----------------------------------------------------------------------------

# Errors in this function will break the build.
function do_before_install() {

  echo "Before install, bring extra tools..."

  if [ "${TRAVIS}" != "true" ]
  then
    # When not running on Travis, clean play arena.
    do_run rm -rf "${work}"
  fi

  do_run clang --version
  do_run clang++ --version

  do_run gcc --version

  if [ "${TRAVIS}" == "true" ]
  then
    if [ "${TRAVIS_OS_NAME}" == "osx" ]
    then
      # Use brew to install specific GCC versions
      # do_run brew tap homebrew/versions

      do_run brew install gcc@5
      do_run brew install gcc@6
      do_run brew install llvm@3.8

      do_run clang-3.8 --version
      do_run clang++-3.8 --version

    elif [ "${TRAVIS_OS_NAME}" == "linux" ]
    then
      # Use addons.apt to install gcc-[56], clang-3.[89]
      do_run clang-3.8 --version
      do_run clang++-3.8 --version

      # do_run clang-3.9 --version
      # do_run clang++-3.9 --version

    fi
  fi

  do_run gcc-5 --version
  do_run g++-5 --version

  do_run gcc-6 --version
  do_run g++-6 --version

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
    do_run curl -L \
    "${eclipse_url}" \
    -o "${cache}/${eclipse_archive_name}"
  fi

  cdt_release="8.8.1"
  cdt_folder="cdt-${cdt_release}"
  cdt_archive_name="${cdt_folder}.zip"
  cdt_archive_url="http://download.eclipse.org/tools/cdt/releases/${cdt_release}/${cdt_archive_name}"

  if [ ! -f "${cache}/${cdt_archive_name}" ]
  then
    do_run curl -L \
    "${cdt_archive_url}" \
    -o "${cache}/${cdt_archive_name}"
  fi

  mkdir -p "${work}"
  cd "${work}"

  do_run rm -rf Eclipse.app eclipse
  do_run tar -x -z -f "${cache}/${eclipse_archive_name}"

  do_run rm -rf "${cdt_folder}"
  mkdir "${cdt_folder}"
  do_run unzip -q -d "${cdt_folder}" "${cache}/${cdt_archive_name}"

  do_run ls -lL

  # Install "C/C++ LLVM-Family Compiler Build Support" feature,
  # which is not present by default in the Eclipse CDT distributions.
  # The p2.os, p2.ws, p2.arch might help to make the right plug-in selection.

  # Eclipse Launcher runt-time options
  # http://help.eclipse.org/mars/index.jsp?topic=%2Forg.eclipse.platform.doc.isv%2Freference%2Fmisc%2Fruntime-options.html

  # Eclipse provisioning, installation management
  # http://help.eclipse.org/mars/index.jsp?topic=%2Forg.eclipse.platform.doc.isv%2Fguide%2Fp2_director.html

  if [ "${TRAVIS_OS_NAME}" == "osx" ]
  then
    do_run "${eclipse}" \
      --launcher.suppressErrors \
      -nosplash \
      -application org.eclipse.equinox.p2.director \
      -repository "file:///${work}/${cdt_folder}" \
      -installIU org.eclipse.cdt.managedbuilder.llvm.feature.group \
      -tag InitialState \
      -destination "${work}/Eclipse.app/" \
      -profileProperties org.eclipse.update.install.features=true \
      -p2.os macosx \
      -p2.ws cocoa \
      -p2.arch x86_64 \
      -roaming 
  elif [ "${TRAVIS_OS_NAME}" == "linux" ]
  then
    do_run "${eclipse}" \
      --launcher.suppressErrors \
      -nosplash \
      -application org.eclipse.equinox.p2.director \
      -repository http://download.eclipse.org/releases/mars/ \
      -installIU org.eclipse.cdt.managedbuilder.llvm.feature.group \
      -tag InitialState \
      -destination "${work}/eclipse/" \
      -profileProperties org.eclipse.update.install.features=true \
      -p2.os linux \
      -p2.ws gtk \
      -p2.arch x86_64 \
      -roaming 
  fi

  return 0
}

# Errors in this function will break the build.
function do_before_script() {

  echo "Before starting the test, generate the projects..."

  # Generate the required folders in the project, from downloaded xPacks. 
  cd "${project}"
  do_run bash scripts/generate.sh "$@"

  # The project is now complete. Import it into the Eclipse workspace.
  do_run rm -rf "${work}/workspace"
  do_run "${eclipse}" \
    --launcher.suppressErrors \
    -nosplash \
    -application org.eclipse.cdt.managedbuilder.core.headlessbuild \
    -data "${work}/workspace" \
    -import "${project}"

  return 0
}

# Errors in this function will break the build.
function do_script() {

  echo "The main test code; perform the tests..."

  cd "${slug}"

  # Build & run configurations.
  if [ "${TRAVIS_OS_NAME}" == "osx" ]
  then
    cfgs=( \
      "test-cmsis-rtos-valid-clang-release" \
      "test-cmsis-rtos-valid-gcc-release" \
      "test-cmsis-rtos-valid-gcc5-release" \
      "test-cmsis-rtos-valid-gcc6-release" \
      "test-rtos-clang-release" \
      "test-rtos-gcc-release" \
      "test-rtos-gcc5-release" \
      "test-mutex-stress-clang-release" \
      "test-mutex-stress-gcc-release" \
      "test-mutex-stress-gcc5-release" \
      "test-cmsis-rtos-valid-clang-debug" \
      "test-cmsis-rtos-valid-gcc-debug" \
      "test-cmsis-rtos-valid-gcc5-debug" \
      "test-cmsis-rtos-valid-gcc6-debug" \
      "test-rtos-clang-debug" \
      "test-rtos-gcc-debug" \
      "test-rtos-gcc5-debug" \
    )
    _cfgs=( \
    )
  elif [ "${TRAVIS_OS_NAME}" == "linux" ]
  then
    cfgs=( \
      "test-cmsis-rtos-valid-clang38-release" \
      "test-cmsis-rtos-valid-clang38-debug" \
      "test-cmsis-rtos-valid-gcc5-release" \
      "test-cmsis-rtos-valid-gcc5-debug" \
      "test-cmsis-rtos-valid-gcc6-release" \
      "test-cmsis-rtos-valid-gcc6-debug" \
      # "test-rtos-clang38-release" \
      # "test-rtos-clang38-debug" \
      "test-rtos-gcc5-release" \
      "test-rtos-gcc5-debug" \
      # GCC 6.2 fails with header error.
      # "test-rtos-gcc6-release"
      # "test-rtos-gcc6-debug"
      # Mutex stress as release only, debug too heavy.
      "test-mutex-stress-clang38-release" \
      "test-mutex-stress-gcc5-release" \
    )
    _cfgs=( \
    )
  fi

  for cfg in "${cfgs[@]}"
  do
    echo
    echo Build ${cfg}
  
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
      
    set -o errexit 

    if [ -f "${project}/${cfg}/${cfg}" ]
    then
      echo
      echo Run ${cfg}
      do_run_quietly "${project}/${cfg}/${cfg}"
    else
      if [ -f "${work}/output.log" ]
      then
        cat "${work}/output.log"
      fi
      echo
      echo "FAILED"
      return 2
    fi
  done

  # Build only configurations (trace output too heavy to run).
  cfgs=( \
    "test-mutex-stress-clang-debug" \
  )

  for cfg in "${cfgs[@]}"
  do
    echo
    echo Build ${cfg}

    # Temporarily disable errors, because (???); 
    # if the build fails, there will be no binary and the next test will fai-.
    set +o errexit 
    do_run_quietly "${eclipse}" \
      --launcher.suppressErrors \
      -nosplash \
      -application org.eclipse.cdt.managedbuilder.core.headlessbuild \
      -data "${work}/workspace" \
      -cleanBuild synthetic-posix-tests-micro-os-plus/${cfg} 
      
    set -o errexit 

    if [ ! -f "${project}/${cfg}/${cfg}" ]
    then
      if [ -f "${work}/output.log" ]
      then
        cat "${work}/output.log"
      fi
      echo
      echo "FAILED"
      return 2
    fi
  done

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
