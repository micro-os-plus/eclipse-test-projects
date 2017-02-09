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

# https://docs.travis-ci.com/user/environment-variables/#Default-Environment-Variables

set +o nounset # Ignore if variable not set.
is_travis=${TRAVIS:-false}
set -o nounset # Exit if variable not set.

# "Darwin", "Linux"
host_uname="$(uname)"

if [ "${is_travis}" == "true" ]
then
  work="$HOME"
  build="${HOME}/build"
  cache="${HOME}/downloads"
else
  work="${HOME}/Work/travis"
  build="${HOME}/Work/travis"
  if [ "${host_uname}" == "Darwin" ]
  then
    cache="${HOME}/Library/Caches/Travis"
  elif [ "${host_uname}" == "Linux" ]
    cache="${HOME}/.cache/travis"
  fi
fi

if [ "${host_uname}" == "Darwin" ]
then
  eclipse="${work}/Eclipse.app/Contents/MacOS/eclipse" 
elif [ "${host_uname}" == "Linux" ]
  eclipse="${work}/eclipse/eclipse"
fi

export work
export build
export cache

mkdir -p "${work}"
mkdir -p "${cache}"

# -----------------------------------------------------------------------------

function do_run()
{
  echo "\$ $@"
  "$@"
}

# -----------------------------------------------------------------------------

# Errors in this function will break the build.
function do_before_install() {

  echo "Before install, bring extra tools..."

  do_run clang --version
  do_run gcc --version

  if [ "${is_travis}" == "true" ]
  then
    if [ "${TRAVIS_OS_NAME}" == "osx" ]
    then
      # Use brew to install specific GCC versions
      do_run brew tap homebrew/versions

      do_run brew install gcc5
      # do_run brew install gcc6

      eclipse_archive_name=eclipse-cpp-mars-2-macosx-cocoa-x86_64.tar.gz
    elif [ "${TRAVIS_OS_NAME}" == "linux" ]
      do_run sudo add-apt-repository ppa:jonathonf/gcc-5.4
      do_run sudo apt-get -yes -quiet update
      do_run sudo apt-get -yes -quiet install gcc-5 g++-5

      eclipse_archive_name=eclipse-cpp-mars-2-linux-gtk-x86_64.tar.gz
    fi
  fi

  if [ ! -f "${cache}/${eclipse_archive_name}" ]
  then
    do_run curl -L \
    "http://artfiles.org/eclipse.org//technology/epp/downloads/release/mars/2/${eclipse_archive_name}" \
    -o "${cache}/${eclipse_archive_name}"
  fi

  cd "${work}"

  do_run rm -rf Eclipse.app eclipse
  do_run tar -x -f "${cache}/${eclipse_archive_name}"

  do_run ls -lL
  
  # Install "C/C++ LLVM-Family Compiler Build Support" feature,
  # which is not present by default in the Eclipse CDT distributions.
  # Eclipse Launcher runt-time options
  # http://help.eclipse.org/mars/index.jsp?topic=%2Forg.eclipse.platform.doc.isv%2Freference%2Fmisc%2Fruntime-options.html
  # Eclipse provisioning, installation management
  # http://help.eclipse.org/mars/index.jsp?topic=%2Forg.eclipse.platform.doc.isv%2Fguide%2Fp2_director.html

  if [ "${host_uname}" == "Darwin" ]
  then
    do_run "${work}/Eclipse.app/Contents/MacOS/eclipse" \
      --launcher.suppressErrors \
      -nosplash \
      -application org.eclipse.equinox.p2.director \
      -repository http://download.eclipse.org/releases/mars/ \
      -installIU org.eclipse.cdt.managedbuilder.llvm.feature.group \
      -tag InitialState \
      -destination "${work}/Eclipse.app/" \
      -profileProperties org.eclipse.update.install.features=true \
      -p2.os macosx \
      -p2.ws cocoa \
      -p2.arch x86_64 \
      -roaming 
  elif [ "${host_uname}" == "Linux" ]
    do_run "${work}/eclipse/eclipse" \
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

  # For just in case.
  cd "${HOME}"

  project="${TRAVIS_BUILD_DIR}/synthetic-posix-tests-micro-os-plus"

  # Generate the required folders in the project, from downloaded xPacks. 
  cd "${project}"
  do_run bash scripts/generate.sh

  # The project is now complete. Import it into the Eclipse workspace.
  do_run rm -rf "${build}/workspace"
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

  # Not passing:
  # "test-rtos-gcc6-release"

  for cfg in "${cfgs[@]}"
  do
    echo
    echo Build ${cfg}
  
    # Temporarily disable errors, because (???); 
    # if the build fails, the attempt to run the binary will fail anyway.
    set +o errexit 

    # Clean build a configuration.
    do_run "${eclipse}" \
      --launcher.suppressErrors \
      -nosplash \
      -application org.eclipse.cdt.managedbuilder.core.headlessbuild \
      -data "${work}/workspace" \
      -cleanBuild synthetic-posix-tests-micro-os-plus/${cfg}
    set -o errexit 

    echo
    echo Run ${cfg}

    do_run "${project}/${cfg}/${cfg}"
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
    do_run "${eclipse}" \
      --launcher.suppressErrors \
      -nosplash \
      -application org.eclipse.cdt.managedbuilder.core.headlessbuild \
      -data "${work}/workspace" \
      -cleanBuild synthetic-posix-tests-micro-os-plus/${cfg}
    set -o errexit 

    if [ ! -f "${project}/${cfg}/${cfg}" ]
    then
      return 2
    fi
  done

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



if false
then

pwd
uname -a

clang --version
gcc --version
gcc-5 --version
gcc-6 --version

java -version

# cd ${HOME}
if [ "${USER}" == "travis" ]
then
  work="$HOME"
  cache="${HOME}/Downloads"
else
  work="${HOME}/Work/travis"
  cache="${HOME}/Library/Caches/Travis"
fi

mkdir -p "${cache}"

eclipse_archive_name=eclipse-cpp-mars-2-macosx-cocoa-x86_64.tar.gz
if [ ! -f "${cache}/${eclipse_archive_name}" ]
then
  curl -L "http://artfiles.org/eclipse.org//technology/epp/downloads/release/mars/2/${eclipse_archive_name}" \
    -o "${cache}/${eclipse_archive_name}"
fi

mkdir -p "${work}"
cd "${work}"

# Create a fresh Eclipse
rm -rf Eclipse.app 
tar xf "${cache}/${eclipse_archive_name}"

# Install "C/C++ LLVM-Family Compiler Build Support" feature,
# which is not present by default in the Eclipse CDT distributions.
"${work}/Eclipse.app/Contents/MacOS/eclipse" --launcher.suppressErrors \
-nosplash \
-application org.eclipse.equinox.p2.director \
-repository http://download.eclipse.org/releases/mars/ \
-installIU org.eclipse.cdt.managedbuilder.llvm.feature.group \
-tag InitialState \
-destination "${work}/Eclipse.app/" \
-profileProperties org.eclipse.update.install.features=true \
-p2.os macosx \
-p2.ws cocoa \
-p2.arch x86_64 \
-roaming 
 
mkdir -p "${work}/build"
cd "${work}/build"
if [ "${USER}" != "travis" ]
then
  chmod -R a+w "micro-os-plus/eclipse-test-projects"
  rm -rf "micro-os-plus/eclipse-test-projects"
  git clone --branch=master \
    https://github.com/micro-os-plus/eclipse-test-projects.git \
    "micro-os-plus/eclipse-test-projects"
fi

# Generate the required folders in the project, from downloaded xPacks. 
cd "${work}/build/micro-os-plus/eclipse-test-projects/synthetic-posix-tests-micro-os-plus"
bash scripts/generate.sh

project="${work}/build/micro-os-plus/eclipse-test-projects/synthetic-posix-tests-micro-os-plus"

# The project is now complete. Import it into the Eclipse workspace.
rm -rf "${work}/workspace"
"${work}/Eclipse.app/Contents/MacOS/eclipse" --launcher.suppressErrors \
-nosplash \
-application org.eclipse.cdt.managedbuilder.core.headlessbuild \
-data "${work}/workspace" \
-import "${project}"

# Build & run configurations.
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

# Not passing:
# "test-rtos-gcc6-release"

for cfg in "${cfgs[@]}"
do
  echo
  echo Build ${cfg}
  
  set +o errexit 
  "${work}/Eclipse.app/Contents/MacOS/eclipse" --launcher.suppressErrors \
    -nosplash \
    -application org.eclipse.cdt.managedbuilder.core.headlessbuild \
    -data "${work}/workspace" \
    -cleanBuild synthetic-posix-tests-micro-os-plus/${cfg}
  set -o errexit 

  echo
  echo Run ${cfg}

  "${project}/${cfg}/${cfg}"
done

# Build only configurations (trace output too heavy to run).
cfgs=( \
  "test-mutex-stress-clang-debug" \
)

for cfg in "${cfgs[@]}"
do
  echo
  echo Build ${cfg}

  set +o errexit 
  "${work}/Eclipse.app/Contents/MacOS/eclipse" --launcher.suppressErrors \
    -nosplash \
    -application org.eclipse.cdt.managedbuilder.core.headlessbuild \
    -data "${work}/workspace" \
    -cleanBuild synthetic-posix-tests-micro-os-plus/${cfg}
  set -o errexit 

  if [ ! -f "${project}/${cfg}/${cfg}" ]
  then
    echo
    echo "FAILED"
    exit 2
  fi
done

echo
echo "PASSED"

exit 0

fi
