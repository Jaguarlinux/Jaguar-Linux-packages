#!/bin/bash

set -e

TRAVIS_MIRROR=https://mirror.ps4jaguarlinux.site/current
for _i in etc/dulge.d/repos-remote*.conf ; do
    /bin/echo -e "\x1b[32mUpdating $_i...\x1b[0m"
    sed -i "s:mirror\.ps4jaguarlinux\.site:$TRAVIS_MIRROR:g" $_i
done
