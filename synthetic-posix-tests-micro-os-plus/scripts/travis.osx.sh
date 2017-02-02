#!/usr/bin/env bash

if [[ ${DEBUG} != "" ]]; then
  set -x 
fi

set -o errexit 
set -o pipefail 
set -o nounset 

IFS=$'\n\t'

# https://gist.github.com/ilg-ul/383869cbb01f61a51c4d
# ----------------------------------------------------------------------------

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
