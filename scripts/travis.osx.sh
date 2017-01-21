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
java -version

cd $HOME

eclipse_archive_name=eclipse-cpp-mars-2-macosx-cocoa-x86_64.tar.gz
curl -L "http://artfiles.org/eclipse.org//technology/epp/downloads/release/mars/2/${eclipse_archive_name}" \
-o $HOME/Downloads/${eclipse_archive_name}

tar xf $HOME/Downloads/${eclipse_archive_name}

cd $HOME/build/micro-os-plus/eclipse-test-projects/synthetic-posix-tests-micro-os-plus
bash scripts/generate.sh

$HOME/Eclipse.app/Contents/MacOS/eclipse --launcher.suppressErrors -nosplash \
-application org.eclipse.cdt.managedbuilder.core.headlessbuild \
-data $HOME/workspace \
-import $HOME/build/micro-os-plus/eclipse-test-projects/synthetic-posix-tests-micro-os-plus \
-cleanBuild synthetic-posix-tests-micro-os-plus/test-cmsis-rtos-valid-clang-debug \
-cleanBuild synthetic-posix-tests-micro-os-plus/test-cmsis-rtos-valid-clang-release \
-cleanBuild synthetic-posix-tests-micro-os-plus/test-mutex-stress-clang-debug \
-cleanBuild synthetic-posix-tests-micro-os-plus/test-mutex-stress-clang-release \
-cleanBuild synthetic-posix-tests-micro-os-plus/test-rtos-clang-debug \
-cleanBuild synthetic-posix-tests-micro-os-plus/test-rtos-clang-release \


