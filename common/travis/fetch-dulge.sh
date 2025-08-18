#!/bin/bash
#
# fetch-dulge.sh

command -v dulge-uhelper >/dev/null && exit
TAR=tar
command -v bsdtar >/dev/null && TAR=bsdtar
ARCH=$(uname -m)-musl
VERSION=0.59_5
URL="https://mirror.ps4jaguarlinux.site/current/dulge-static-static-${VERSION}.${ARCH}.tar.xz"
FILE=${URL##*/}

mkdir -p /tmp/bin

/bin/echo -e '\x1b[32mInstalling dulge...\x1b[0m'
if command -v wget >/dev/null; then
	wget -q -O "$FILE" "$URL" || exit 1
else
	curl -s -o "$FILE" "$URL" || exit 1
fi

$TAR xf "$FILE" -C /tmp/bin --strip-components=3 ./usr/bin || exit 1
