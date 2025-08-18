#!/bin/sh

uname=$(/usr/bin/uname $@)
rv=$?
uname_m=$(/usr/bin/uname -m)
arch=${DULGE_ARCH%-musl}
# if DULGE_ARCH was reseted by `env -i` use original `/usr/bin/uname -m`
: ${arch:=$uname_m}
echo "$uname" |
	sed "s/\(^\| \)$(/usr/bin/uname -n)\($\| \)/\1jaguar\2/" |
	sed "s/$uname_m/$arch/"

exit $rv
