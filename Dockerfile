FROM ubuntu AS wavs

ARG DEBIAN_FRONTEND=noninteractive
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    apt update && \
    apt install --assume-yes lame && \
    mkdir /sounds

COPY sounds/* /sounds
RUN for FILE in $( find /sounds -name "*.mp3" ) ; do \
        if [ ! -f ${FILE%.*}.wav ] ; then \
            lame --decode $FILE ${FILE%.*}.wav ; \
        fi ; \
    done


FROM mlan/asterisk:latest

COPY etc/asterisk/* /etc/asterisk
COPY --from=wavs /sounds /var/lib/asterisk/sound

