#!/bin/bash

set -e
set -o pipefail
set -u

DIRNAME=$( realpath $( dirname $0 ) )
pushd $DIRNAME/sounds/raw > /dev/null
    [[ "$( find . -type f \
             -and -not -name "intro.wav" \
             -and -not -name md5.cksum \
             -and -not -name "marshall-*.wav" \
             -and -not -name "rubble-*.wav" \
             -and -not -name "chase-*.wav" \
             -and -not -name "rocky-*.wav" \
             -and -not -name "zuma-*.wav" \
             -and -not -name "sky-*.wav" \
             -and -not -name "ryder-*.wav" )" == "" ]] && exit 0 || exit 1
