#!/bin/bash
#
# vim: set ts=4 sw=4 et:
#
# Passed arguments:
# 	$1 - pkgname [REQUIRED]
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

for f in $DULGE_COMMONDIR/environment/fetch/*.sh; do
    source_file "$f"
done

DULGE_FETCH_DONE="${DULGE_STATEDIR}/${sourcepkg}_${DULGE_CROSS_BUILD}_fetch_done"

if [ -f "$DULGE_FETCH_DONE" ]; then
    exit 0
fi

# Run pre-fetch hooks.
run_pkg_hooks pre-fetch

# If template defines pre_fetch(), use it.
if declare -f pre_fetch >/dev/null; then
    run_func pre_fetch
fi

# If template defines do_fetch(), use it rather than the hooks.
if declare -f do_fetch >/dev/null; then
    cd ${DULGE_BUILDDIR}
    [ -n "$build_wrksrc" ] && mkdir -p "$wrksrc"
    run_func do_fetch
else
    # Run do-fetch hooks.
    run_pkg_hooks "do-fetch"
fi

cd ${DULGE_BUILDDIR} || msg_error "$pkgver: cannot access wrksrc directory [$wrksrc]\n"
# if templates defines post_fetch(), use it.
if declare -f post_fetch >/dev/null; then
    run_func post_fetch
fi

# Run post-fetch hooks.
run_pkg_hooks post-fetch

touch -f $DULGE_FETCH_DONE

exit 0
