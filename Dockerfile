# TODO: specify tag
# TODO: asterisk version as a build arg
FROM ubuntu AS build

# TODO: put asterisk tar source file in a cache
# TODO: probably don't need libncurses5-dev--I presume it's only used in `make menuselect`
# TODO: I removed `add-apt-repository universe`

# In `install_prereq install`, libvpb1 waits for you to enter your local
# country code
# TODO: follow https://community.asterisk.org/t/avoiding-install-prompts-when-using-contrib-scripts-install-prereq-in-debian-ubuntu/86208
# to resolve
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    apt update && \
    apt install --assume-yes \
                build-essential \
                curl \
                debconf-utils \
                git \
                libjansson-dev \
                libncurses5-dev \
                libnewt-dev \
                libsqlite3-dev \
                libssl-dev \
                libxml2-dev  \
                subversion \
                uuid-dev \
                wget && \
    if [ ! -f /tmp/asterisk-21.0.1.tar.gz ] ; then \
        wget https://downloads.asterisk.org/pub/telephony/asterisk/old-releases/asterisk-21.0.1.tar.gz \
             --output-document=/tmp/asterisk-21.0.1.tar.gz ; \
    fi && \
    cd /tmp && \
    tar xvf asterisk-21.0.1.tar.gz && \
    cd asterisk-*/ && \
        contrib/scripts/get_mp3_source.sh && \
        echo 'libvpb1 libvpb1/countrycode     string  1' | debconf-set-selections -v && \
        contrib/scripts/install_prereq install && \
        ./configure && \
        make -j $( nproc ) && \
    cd -

