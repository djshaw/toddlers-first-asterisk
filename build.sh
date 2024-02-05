#!/bin/bash

set -e
set -x
set -o pipefail
set -u

if [ "$EUID" -ne 0 ] ; then
    # This script needs to run as root so it can install binaries
    sudo $0
    exit $?
fi

# TODO: probably don't need libncurses5-dev--I presume it's only used in `make menuselect`
export DEBIAN_FRONTEND=noninteractive

ASTERISK_VERSION=21.0.1
if [[ ! $( asterisk -V ) =~ ${ASTERISK_VERSION}$ ]] ; then
    apt update
    apt install --assume-yes \
                build-essential \
                curl \
                debconf-utils \
                git \
                lame \
                libjansson-dev \
                libncurses5-dev \
                libnewt-dev \
                libsqlite3-dev \
                libssl-dev \
                libxml2-dev  \
                sox \
                subversion \
                tzdata \
                uuid-dev \
                wget

    if [ ! -f /tmp/asterisk-$ASTERISK_VERSION.tar.gz ] ; then
        wget https://downloads.asterisk.org/pub/telephony/asterisk/old-releases/asterisk-$ASTERISK_VERSION.tar.gz \
             --output-document=/tmp/asterisk-$ASTERISK_VERSION.tar.gz
    fi

    pushd /tmp
        # TODO: it wouldn't be unreasonable to untar and build in a temporary
        # directory
        # Only unpack if we've not unpacked before. Otherwise, any subsequent
        # builds will rebuild everything
        if [[ ! -d asterisk-$ASTERISK_VERSION ]] ; then
            tar xvf asterisk-$ASTERISK_VERSION.tar.gz
        fi
        pushd asterisk-*/
            # If the mp3 source is already downloaded, get_mp3_source.sh will
            # return a non-0 value
            contrib/scripts/get_mp3_source.sh || true
            # In `install_prereq install`, libvpb1 waits for you to enter your local
            # country code
            echo 'libvpb1 libvpb1/countrycode     string  1' | debconf-set-selections -v

            # install_prereq fails if it was already run
            contrib/scripts/install_prereq install || true
            ./configure
            make -j $( nproc )
            make install
            # TODO: can we drop `make samples`?
            make samples
            make config
            ldconfig
        popd
    popd
fi

cp etc/asterisk/* /etc/asterisk

# groupadd and useradd fails if the group already exists
groupadd asterisk || true
useradd -r -d /var/lib/asterisk -g asterisk asterisk || true
usermod -aG audio,dialout asterisk
chown -R asterisk:asterisk /etc/asterisk \
                           /var/{lib,log,spool}/asterisk \
                           /usr/lib/asterisk

# TODO: dynamically generate a dialplan based on the files found
# TODO: the credentials 6001/unsecurepassword come from the tutorial I
#       followed.  Pick better credentials.
cp etc/asterisk/* /etc/asterisk/
chmod -R 644 /var/{lib,log,run,spool}/asterisk \
             /usr/lib/asterisk \
             /etc/asterisk
find /var/{lib,log,run,spool}/asterisk \
     /usr/lib/asterisk \
     /etc/asterisk -type d | xargs chmod 755

sed -i "s/\#AST_USER=\"asterisk\"/AST_USER=\"asterisk\"/g" /etc/default/asterisk
sed -i "s/\#AST_GROUP=\"asterisk\"/AST_GROUP=\"asterisk\"/g" /etc/default/asterisk

if ! grep "runuser = asterisk ;" /etc/asterisk/asterisk.conf ; then
    echo -e "runuser = asterisk ;\nrungroup = asterisk ;\n" >> /etc/asterisk/asterisk.conf
fi

# I don't want to host the mp3 files because I don't know I'm allowed to host
# them. Get the source files from a place that only I can access.
mkdir -p sounds/raw
scp -B cerf@git.djshaw.ca:sounds/* sounds/raw || true
rm sounds/*.wav

# TODO: The next evolution of this project is to support multiple callouts from the same character.
#       When multiple callouts from the same character exist, asterisk will randomly select a 
#       callout to play.  This code removes everything after the `-` character.  We will want to
#       preserve the full filename and instead modify extensions.conf to dynamically pick a file to
#       play.
for FILE in $( ls sounds/raw/*.wav ) ; do
    FILE_BASENAME=$( basename $FILE )
    if [[ "$FILE_BASENAME" == *"-"* ]] ; then
        FILE_BASENAME=${FILE_BASENAME%-*}
    else
        FILE_BASENAME=${FILE_BASENAME%.*}
    fi
    sox $FILE --channels 1 --bits 16 --rate 8000 sounds/${FILE_BASENAME}.wav
done

set +x
rm -rf /var/lib/asterisk/sounds/en/{.*,*}
set -x
cp sounds/*.wav /var/lib/asterisk/sounds/en/ || true

# There are too many files for the -x output to be useful
set +x
chown asterisk:asterisk /var/lib/asterisk/sounds/en/*
chmod 644 /var/lib/asterisk/sounds/en/*
set -x

systemctl restart asterisk
systemctl enable asterisk
systemctl --no-pager --full status asterisk

