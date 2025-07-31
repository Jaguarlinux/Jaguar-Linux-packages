#!/bin/bash
#
# vim: set ts=4 sw=4 et:
#
# Passed arguments:
#   $1 - current pkgname to build [REQUIRED]
#   $2 - target pkgname (origin) to build [REQUIRED]
#   $3 - dulge target [REQUIRED]
#   $4 - cross target [OPTIONAL]
#   $5 - internal [OPTIONAL]

if [ $# -lt 3 -o $# -gt 5 ]; then
    echo "${0##*/}: invalid number of arguments: pkgname targetpkg target [cross-target]"
    exit 1
fi

readonly PKGNAME="$1"
readonly DULGE_TARGET_PKG="$2"
readonly DULGE_TARGET="$3"
readonly DULGE_CROSS_BUILD="$4"
readonly DULGE_CROSS_PREPARE="$5"

export DULGE_TARGET

for f in $DULGE_SHUTILSDIR/*.sh; do
    . $f
done

last="${DULGE_DEPENDS_CHAIN##*,}"
case "$DULGE_DEPENDS_CHAIN" in
    *,$last,*)
        msg_error "Build-time cyclic dependency$last,${DULGE_DEPENDS_CHAIN##*,$last,} detected.\n"
esac

setup_pkg "$PKGNAME" $DULGE_CROSS_BUILD
readonly SOURCEPKG="$sourcepkg"

check_existing_pkg

show_pkg_build_options
check_pkg_arch $DULGE_CROSS_BUILD

if [ -z "$DULGE_CROSS_PREPARE" ]; then
    prepare_cross_sysroot $DULGE_CROSS_BUILD || exit $?
fi
# Install dependencies from binary packages
if [ "$PKGNAME" != "$DULGE_TARGET_PKG" -o -z "$DULGE_SKIP_DEPS" ]; then
    install_pkg_deps $PKGNAME $DULGE_TARGET_PKG pkg $DULGE_CROSS_BUILD $DULGE_CROSS_PREPARE || exit $?
fi

if [ "$DULGE_CROSS_BUILD" ]; then
    install_cross_pkg $DULGE_CROSS_BUILD || exit $?
fi

# Fetch distfiles after installing required dependencies,
# because some of them might be required for do_fetch().
$DULGE_LIBEXECDIR/dulge-src-dofetch.sh $SOURCEPKG $DULGE_CROSS_BUILD || exit 1
[ "$DULGE_TARGET" = "fetch" ] && exit 0

# Fetch, extract, build and install into the destination directory.
$DULGE_LIBEXECDIR/dulge-src-doextract.sh $SOURCEPKG $DULGE_CROSS_BUILD || exit 1
[ "$DULGE_TARGET" = "extract" ] && exit 0

# Run patch phrase
$DULGE_LIBEXECDIR/dulge-src-dopatch.sh $SOURCEPKG $DULGE_CROSS_BUILD || exit 1
[ "$DULGE_TARGET" = "patch" ] && exit 0

# Run configure phase
$DULGE_LIBEXECDIR/dulge-src-doconfigure.sh $SOURCEPKG $DULGE_CROSS_BUILD || exit 1
[ "$DULGE_TARGET" = "configure" ] && exit 0

# Run build phase
$DULGE_LIBEXECDIR/dulge-src-dobuild.sh $SOURCEPKG $DULGE_CROSS_BUILD || exit 1
[ "$DULGE_TARGET" = "build" ] && exit 0

# Run check phase
$DULGE_LIBEXECDIR/dulge-src-docheck.sh $SOURCEPKG $DULGE_CROSS_BUILD || exit 1
[ "$DULGE_TARGET" = "check" ] && exit 0

# Install pkgs into destdir.
$DULGE_LIBEXECDIR/dulge-src-doinstall.sh $SOURCEPKG no $DULGE_CROSS_BUILD || exit 1

for subpkg in ${subpackages} ${sourcepkg}; do
    $DULGE_LIBEXECDIR/dulge-src-doinstall.sh $subpkg yes $DULGE_CROSS_BUILD || exit 1
done
for subpkg in ${subpackages} ${sourcepkg}; do
    $DULGE_LIBEXECDIR/dulge-src-prepkg.sh $subpkg $DULGE_CROSS_BUILD || exit 1
done

for subpkg in ${subpackages} ${sourcepkg}; do
    if [ "$PKGNAME" = "${subpkg}" -a "$DULGE_TARGET" = "install" ]; then
        exit 0
    fi
done

# Clean list of preregistered packages
printf "" > ${DULGE_STATEDIR}/.${sourcepkg}_register_pkg
# If install went ok generate the binpkgs.
for subpkg in ${subpackages} ${sourcepkg}; do
    $DULGE_LIBEXECDIR/dulge-src-dopkg.sh $subpkg "$DULGE_REPOSITORY" "$DULGE_CROSS_BUILD" || exit 1
done

# Registering packages at once per repository. This makes sure that staging is
# triggered for all new packages if any of them introduces inconsistencies.
cut -d: -f 1,2 ${DULGE_STATEDIR}/.${sourcepkg}_register_pkg | sort -u | \
    while IFS=: read -r arch repo; do
        paths=$(grep "^$arch:$repo:" "${DULGE_STATEDIR}/.${sourcepkg}_register_pkg" | \
            cut -d : -f 2,3 | tr ':' '/')
        if [ -z "$DULGE_PRESERVE_PKGS" ] || [ "$DULGE_BUILD_FORCEMODE" ]; then
            force=-f
        fi
        if [ -n "${arch}" ]; then
            msg_normal "Registering new packages to $repo ($arch)\n"
            DULGE_TARGET_ARCH=${arch} $DULGE_RINDEX_CMD \
                ${DULGE_REPO_COMPTYPE:+--compression $DULGE_REPO_COMPTYPE} ${force} -a ${paths}
        else
            msg_normal "Registering new packages to $repo\n"
            if [ -n "$DULGE_CROSS_BUILD" ]; then
                $DULGE_RINDEX_XCMD ${DULGE_REPO_COMPTYPE:+--compression $DULGE_REPO_COMPTYPE} \
					${force} -a ${paths}
            else
                $DULGE_RINDEX_CMD ${DULGE_REPO_COMPTYPE:+--compression $DULGE_REPO_COMPTYPE} \
					${force} -a ${paths}
            fi
        fi
    done

# pkg cleanup
if declare -f do_clean >/dev/null; then
    run_func do_clean
fi

if [ -n "$DULGE_DEPENDENCY" -o -z "$DULGE_KEEP_ALL" ]; then
    remove_pkg_autodeps
    remove_pkg_wrksrc
    remove_pkg $DULGE_CROSS_BUILD
    remove_pkg_statedir
fi

exit 0
