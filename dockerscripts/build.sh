#!/bin/bash

cd $(dirname $0)/..

cd $1

docker build --build-arg BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.14 -t test_$1 .
