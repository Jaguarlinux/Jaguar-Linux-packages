#!/bin/bash
#
# vim: set ts=4 sw=4 et:
#
# Passed arguments:
#	$1 - pkgname [REQUIRED]
#   $2 - subpkg mode [REQUIRED]
#	$2 - cross target [OPTIONAL]

if [ $# -lt 2 -o $# -gt 3 ]; then
    echo "${0##*/}: invalid number of arguments: pkgname subpkg-mode [cross-target]"
    exit 1
fi

PKGNAME="$1"
SUBPKG_MODE="$2"
DULGE_CROSS_BUILD="$3"

for f in $DULGE_SHUTILSDIR/*.sh; do
    . $f
done

setup_pkg "$PKGNAME" $DULGE_CROSS_BUILD

for f in $DULGE_COMMONDIR/environment/install/*.sh; do
    source_file "$f"
done

DULGE_INSTALL_DONE="${DULGE_STATEDIR}/${sourcepkg}_${DULGE_CROSS_BUILD}_install_done"

ch_wrksrc

if [ "$SUBPKG_MODE"  = "no" ]; then
    if [ ! -f $DULGE_INSTALL_DONE ] || [ -f $DULGE_INSTALL_DONE -a -n "$DULGE_BUILD_FORCEMODE" ]; then
        mkdir -p $DULGE_DESTDIR/$DULGE_CROSS_TRIPLET/$pkgname-$version

        if [ "$metapackage" = yes ]; then
            optional="optional"
        else
            optional=""
        fi

        run_step install "$optional" skip

        touch -f $DULGE_INSTALL_DONE
    fi
    exit 0
fi

DULGE_SUBPKG_INSTALL_DONE="${DULGE_STATEDIR}/${PKGNAME}_${DULGE_CROSS_BUILD}_subpkg_install_done"

# If it's a subpkg execute the pkg_install() function.
if [ ! -f $DULGE_SUBPKG_INSTALL_DONE -o -n "$DULGE_BUILD_FORCEMODE" ]; then
    if [ "$sourcepkg" != "$PKGNAME" ]; then
        # Source all subpkg environment setup snippets.
        for f in ${DULGE_COMMONDIR}/environment/setup-subpkg/*.sh; do
            source_file "$f"
        done

        ${PKGNAME}_package
        pkgname=$PKGNAME

        if [ "$build_style" = meta ]; then
            msg_error "$pkgver: build_style=meta is deprecated, replace with metapackage=yes\n"
        fi

        source_file $DULGE_COMMONDIR/environment/build-style/${build_style}.sh

        install -d $PKGDESTDIR
        if declare -f pkg_install >/dev/null; then
            run_pkg_hooks pre-install
            run_func pkg_install
        fi
    fi
    setup_pkg_depends ${pkgname:=$PKGNAME} || exit 1
    run_pkg_hooks post-install
    touch -f $DULGE_SUBPKG_INSTALL_DONE
fi

exit 0
