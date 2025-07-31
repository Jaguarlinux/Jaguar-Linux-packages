#!/bin/bash
#
# vim: set ts=4 sw=4 et:
#
# Passed arguments:
#	$1 - pkgname to configure [REQUIRED]
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

DULGE_CONFIGURE_DONE="${DULGE_STATEDIR}/${sourcepkg}_${DULGE_CROSS_BUILD}_configure_done"

if [ -f $DULGE_CONFIGURE_DONE -a -z "$DULGE_BUILD_FORCEMODE" ] ||
   [ -f $DULGE_CONFIGURE_DONE -a -n "$DULGE_BUILD_FORCEMODE" -a $DULGE_TARGET != "configure" ]; then
    exit 0
fi

for f in $DULGE_COMMONDIR/environment/configure/*.sh; do
    source_file "$f"
done

run_step configure optional

touch -f $DULGE_CONFIGURE_DONE

exit 0
