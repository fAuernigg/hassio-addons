
ARG BUILD_FROM
FROM $BUILD_FROM

# Add env
ENV LANG C.UTF-8

# Setup base
ARG BUILD_ARCH
ARG CLI_VERSION

RUN apk add --no-cache \
    dbus udev attr bash util-linux curl figlet \
    jq libxml2-utils mosquitto-clients

# Copy data
COPY rootfs /

# for pc testing
#RUN mkdir /data/
#COPY test/options.json /data/options.json
