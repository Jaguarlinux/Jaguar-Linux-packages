#!/bin/bash

set -e

TRAVIS_MIRROR=repo-ci.jaguarlinux.org

for _i in etc/dulge.d/repos-remote*.conf ; do
    /bin/echo -e "\x1b[32mUpdating $_i...\x1b[0m"
    sed -i "s:repo-default\.jaguarlinux\.org:$TRAVIS_MIRROR:g" $_i
done
