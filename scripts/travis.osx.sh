#!/usr/bin/env bash

if [[ ${DEBUG} != "" ]]; then
  set -x 
fi

set -o errexit 
set -o pipefail 
set -o nounset 

IFS=$'\n\t'

# -------------------------------

pwd
uname -a
clang --version
java -version

cd $HOME

eclipse_archive_name=eclipse-cpp-mars-2-macosx-cocoa-x86_64.tar.gz
curl -L "http://artfiles.org/eclipse.org//technology/epp/downloads/release/mars/2/${eclipse_archive_name}"
-o $HOME/Downloads/${eclipse_archive_name}

tar xf $HOME/Downloads/${eclipse_archive_name}

cd $HOME/micro-os-plus/eclipse-test-projects/synthetic-posix-tests-micro-os-plus
bash scripts/generate.sh

$HOME/Eclipse.app/Contents/MacOS/eclipse --launcher.suppressErrors -nosplash \
-application org.eclipse.cdt.managedbuilder.core.headlessbuild \
-data $HOME/workspace \
-import $HOME/micro-os-plus/eclipse-test-projects/synthetic-posix-tests-micro-os-plus
