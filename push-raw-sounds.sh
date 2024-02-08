#!/bin/bash

set -e
set -o pipefail
set -u

DIRNAME=$( realpath $( dirname $0 ) )
pushd $DIRNAME/sounds/raw > /dev/null
    $DIRNAME/check-for-sounds-without-extension.sh || ( >&2 echo "Unexpected files found! Stopping!" ; exit 1 )

    # Check that the existing content is still valid
    md5sum --check md5.cksum --quiet --strict

    # The default samba deployment sets the file mode to 775. Now is a convenient time to remove
    # the execute bit.
    chmod a-x *.wav
    md5sum --text *.wav > md5.cksum
popd > /dev/null

scp -B sounds/raw/{*.wav,md5.cksum} cerf@git.djshaw.ca:sounds

