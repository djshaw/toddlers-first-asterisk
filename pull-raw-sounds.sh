#!/bin/bash

set -e
set -o pipefail
set -u

scp -B cerf@git.djshaw.ca:sounds/* sounds/raw

DIRNAME=$( realpath $( dirname $0 ) )
pushd $DIRNAME/sounds/raw > /dev/null
    md5sum --check md5.cksum --quiet --strict
popd > /dev/null

