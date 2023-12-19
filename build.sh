#!/bin/bash

set -e
set -x
set -o pipefail
set -u

# TODO: specify tag for ubuntu
# TODO: asterisk version as a build arg

# TODO: put asterisk tar source file in a cache
# TODO: probably don't need libncurses5-dev--I presume it's only used in `make menuselect`
export DEBIAN_FRONTEND=noninteractive

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
            subversion \
            tzdata \
            uuid-dev \
            wget
if [ ! -f /tmp/asterisk-21.0.1.tar.gz ] ; then
    wget https://downloads.asterisk.org/pub/telephony/asterisk/old-releases/asterisk-21.0.1.tar.gz \
         --output-document=/tmp/asterisk-21.0.1.tar.gz
fi

pushd /tmp
    # TODO: it wouldn't be unreasonable to untar and build in a temporary
    # directory
    # Only unpack if we've not unpacked before. Otherwise, any subsequent
    # builds will rebuild everything
    if [[ ! -d asterisk-21.0.1 ]] ; then
        tar xvf asterisk-21.0.1.tar.gz
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
        make samples
        make config
        ldconfig
    popd
popd

cp etc/asterisk/* /etc/asterisk

# groupadd and useradd fails if the group already exists
groupadd asterisk || true
useradd -r -d /var/lib/asterisk -g asterisk asterisk || true
usermod -aG audio,dialout asterisk
chown -R asterisk.asterisk /etc/asterisk \
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
scp -B cerf@djshaw.ca:sounds/* sounds || true
for FILE in $( ls sounds/*.mp3 ) ; do
    # TODO: put the output file name in a variable
    lame --decode $FILE /var/lib/asterisk/sounds/en/$( basename $FILE ).wav
    chown asterisk:asterisk /var/lib/asterisk/sounds/en/$( basename $FILE ).wav
    chmod 644 /var/lib/asterisk/sounds/en/$( basename $FILE ).wav
done

systemctl restart asterisk
systemctl enable asterisk
systemctl --no-pager --full status asterisk

