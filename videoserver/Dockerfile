ARG BUILD_FROM
FROM $BUILD_FROM

# Add env
ENV LANG C.UTF-8

# Setup base
ARG BUILD_ARCH
ARG CLI_VERSION

RUN apk add --no-cache \
    dbus udev attr bash util-linux curl openssh-client figlet jq \
    git build-base coreutils linux-headers libc-dev

RUN git clone "https://github.com/FFmpeg/FFmpeg.git" ffmpeg && \
    cd ffmpeg && git checkout 2ca65fc7b74444edd51d5803a2c1e05a801a6023

RUN cd ffmpeg && ./configure --disable-x86asm && make -j4 && make install

RUN rm -rf /var/cache/apk/* \
    && curl -Lso /usr/bin/ha "https://github.com/home-assistant/cli/releases/download/${CLI_VERSION}/ha_${BUILD_ARCH}" \
    && chmod a+x /usr/bin/ha

# Copy data
COPY rootfs /
