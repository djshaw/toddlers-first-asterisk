# TODO: specify tag for ubuntu
# TODO: asterisk version as a build arg
FROM ubuntu AS build

# TODO: put asterisk tar source file in a cache
# TODO: probably don't need libncurses5-dev--I presume it's only used in `make menuselect`
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Toronto
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
                tzdata \
                uuid-dev \
                wget && \
# The asterisk dependencies include tzdata. Because the docker build is
# unattended, we configure the timezone information here
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure --frontend noninteractive tzdata && \
    echo $TZ > /etc/timezone && \
    if [ ! -f /tmp/asterisk-21.0.1.tar.gz ] ; then \
        wget https://downloads.asterisk.org/pub/telephony/asterisk/old-releases/asterisk-21.0.1.tar.gz \
             --output-document=/tmp/asterisk-21.0.1.tar.gz ; \
    fi && \
    cd /tmp && \
    tar xvf asterisk-21.0.1.tar.gz && \
    cd asterisk-*/ && \
        contrib/scripts/get_mp3_source.sh && \
# In `install_prereq install`, libvpb1 waits for you to enter your local
# country code
        echo 'libvpb1 libvpb1/countrycode     string  1' | debconf-set-selections -v && \
        contrib/scripts/install_prereq install && \
        ./configure && \
        make -j $( nproc ) && \
        make install && \
    cd -


#FROM ubuntu AS sox

#RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
#    --mount=target=/var/cache/apt,type=cache,sharing=locked \
#    apt update && apt install sox

# TODO: convert mp3s to wavs


FROM ubuntu AS asterisk

COPY --from=build /var/lib/asterisk /var/lib/
COPY --from=build /var/cache/asterisk /var/cache/
COPY --from=build /var/spool/asterisk /var/spool/
COPY --from=build /etc/asterisk /etc/asterisk/
COPY --from=build /usr/lib/*asterisk* \
                  /usr/lib/*resample* \
                  /usr/lib/*c-client* \
                  /usr/lib/
COPY --from=build /usr/sbin/*asterisk* /usr/sbin/
COPY --from=build /usr/lib/x86_64-linux-gnu/*xml* \
                  /usr/lib/x86_64-linux-gnu/*xslt* \
                  /usr/lib/x86_64-linux-gnu/*sqlite* \
                  /usr/lib/x86_64-linux-gnu/*jansson* \
                  /usr/lib/x86_64-linux-gnu/*uriparser* \
                  /usr/lib/x86_64-linux-gnu/*edit* \
                  /usr/lib/x86_64-linux-gnu/*icuuc* \
                  /usr/lib/x86_64-linux-gnu/*icudata* \
                  /usr/lib/x86_64-linux-gnu/*md* \
                  /usr/lib/x86_64-linux-gnu/*bsd* \
                  /usr/lib/x86_64-linux-gnu
COPY etc/asterisk/* /etc/asterisk/
# TODO: copy my configuration in
