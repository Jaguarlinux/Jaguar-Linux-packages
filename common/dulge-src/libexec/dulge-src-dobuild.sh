#!/bin/bash
#
# vim: set ts=4 sw=4 et:
#
# Passed arguments:
#	$1 - pkgname to build [REQUIRED]
#	$2 - cross target [OPTIONAL]

if [ $# -lt 1 -o $# -gt 2 ]; then
    echo "${0##*/}: invalid number of arguments: pkgname [cross-target]"
    exit 1
fi

PKGNAME="$1"
DULGE_CROSS_BUILD="$2"

for f in $DULGE_SHUTILSDIR/*.sh; do
    . $f
done

setup_pkg "$PKGNAME" $DULGE_CROSS_BUILD

DULGE_BUILD_DONE="${DULGE_STATEDIR}/${sourcepkg}_${DULGE_CROSS_BUILD}_build_done"

if [ -f $DULGE_BUILD_DONE -a -z "$DULGE_BUILD_FORCEMODE" ] ||
   [ -f $DULGE_BUILD_DONE -a -n "$DULGE_BUILD_FORCEMODE" -a $DULGE_TARGET != "build" ]; then
    exit 0
fi

for f in $DULGE_COMMONDIR/environment/build/*.sh; do
    source_file "$f"
done

run_step build optional

touch -f $DULGE_BUILD_DONE

exit 0
