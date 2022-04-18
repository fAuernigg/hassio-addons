#! /bin/bash
mkdir -p /tmp/my_test_data
cp options.json /tmp/my_test_data
docker build --build-arg BUILD_FROM="homeassistant/armv7-base:latest" -t fAuernigg/armv7-addon-knxdevice2json ..
docker run --rm -v /tmp/my_test_data:/data -p 5300 dianlight/armv7-addon-knxdevice2json
