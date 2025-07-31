# vim: set ts=4 sw=4 et:

bulk_getlink() {
    local p="${1##*/}"
    local target="$(readlink $DULGE_SRCPKGDIR/$p)"

    if [ $? -eq 0 -a -n "$target" ]; then
        p=$target
    fi
    echo $p
}

bulk_sortdeps() {
    local _pkgs _pkg pkgs pkg found f x tmpf

    _pkgs="$@"
    # Iterate over the list and make sure that only real pkgs are
    # added to our pkglist.
    for pkg in ${_pkgs}; do
        found=0
        f=$(bulk_getlink $pkg)
        for x in ${pkgs}; do
            if [ "$x" = "${f}" ]; then
                found=1
                break
            fi
        done
        if [ $found -eq 0 ]; then
            pkgs+="${f} "
        fi
    done

    tmpf=$(mktemp) || exit 1
    # Now make the real dependency graph of all pkgs to build.
    # Perform a topological sort of all pkgs but only with build dependencies
    # that are found in previous step.
    for pkg in ${pkgs}; do
        _pkgs="$($DULGE_DISTDIR/dulge-src show-build-deps $pkg 2>/dev/null)"
        found=0
        for x in ${_pkgs}; do
            _pkg=$(bulk_getlink $x)
            for f in ${pkgs}; do
                if [ "${f}" != "${_pkg}" ]; then
                    continue
                fi
                found=1
                echo "${pkg} ${f}" >> $tmpf
            done
        done
        [ $found -eq 0 ] && echo "${pkg} ${pkg}" >> $tmpf
    done
    tsort $tmpf|tac
    rm -f $tmpf
}

bulk_build() {
    local bulk_build_cmd="$1"
    local NPROCS=$(($(nproc)*2))
    local NRUNNING=0

    if [ "$DULGE_CROSS_BUILD" ]; then
        source ${DULGE_COMMONDIR}/cross-profiles/${DULGE_CROSS_BUILD}.sh
        export DULGE_ARCH=${DULGE_TARGET_MACHINE}
    fi
    if ! command -v dulge-checkvers &>/dev/null; then
        msg_error "dulge-src: cannot find dulge-checkvers(1) command!\n"
    fi

    # Compare installed pkg versions vs srcpkgs
    case "$bulk_build_cmd" in
    installed)
        bulk_sortdeps $(dulge-checkvers -f '%n' -I -D "$DULGE_DISTDIR")
        return $?
        ;;
    local)
        bulk_sortdeps $(dulge-checkvers -f '%n' -i -R "${DULGE_REPOSITORY}/bootstrap" -R "${DULGE_REPOSITORY}" -R "${DULGE_REPOSITORY}/nonfree" -D "$DULGE_DISTDIR")
        return $?
        ;;
    esac

    # compare repo pkg versions vs srcpkgs
    for f in $(dulge-checkvers -f '%n' -D $DULGE_DISTDIR); do
        if [ $NRUNNING -eq $NPROCS ]; then
            NRUNNING=0
            wait
        fi
        NRUNNING=$((NRUNNING+1))
        (
            setup_pkg $f $DULGE_TARGET_MACHINE &>/dev/null
            if show_avail &>/dev/null; then
                echo "$f"
            fi
        ) &
    done
    wait
    return $?
}

bulk_update() {
    local bulk_update_cmd="$1" pkgs f rval

    pkgs="$(bulk_build "${bulk_update_cmd}")"
    [[ -z $pkgs ]] && return 0

    msg_normal "dulge-src: the following packages must be rebuilt and updated:\n"
    for f in ${pkgs}; do
        echo " $f"
    done
    for f in ${pkgs}; do
        DULGE_TARGET_PKG=$f
        read_pkg
        msg_normal "dulge-src: building ${pkgver} ...\n"
        if [ -n "$CHROOT_READY" -a -z "$IN_CHROOT" ]; then
            chroot_handler pkg $DULGE_TARGET_PKG
        else
            $DULGE_LIBEXECDIR/build.sh $f $f pkg $DULGE_CROSS_BUILD
        fi
        if [ $? -eq 1 ]; then
            msg_error "dulge-src: failed to build $pkgver pkg!\n"
        fi
    done
    if [ -n "$pkgs" -a "$bulk_update_cmd" == installed ]; then
        echo
        msg_normal "dulge-src: updating your system, confirm to proceed...\n"
        ${DULGE_SUCMD} "dulge-install --repository=$DULGE_REPOSITORY/bootstrap --repository=$DULGE_REPOSITORY --repository=$DULGE_REPOSITORY/nonfree -u ${pkgs//[$'\n']/ }" || return 1
    fi
}
