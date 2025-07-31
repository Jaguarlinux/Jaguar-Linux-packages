# vim: set ts=4 sw=4 et:

check_existing_pkg() {
    local arch= curpkg=
    if [ -z "$DULGE_PRESERVE_PKGS" ] || [ "$DULGE_BUILD_FORCEMODE" ]; then
        return
    fi
    arch=$DULGE_TARGET_MACHINE
    curpkg=$DULGE_REPOSITORY/$repository/$pkgver.$arch.dulge
    if [ -e $curpkg ]; then
        msg_warn "$pkgver: skipping build due to existing $curpkg\n"
        exit 0
    fi
}

check_pkg_arch() {
    local cross="$1" _arch f match nonegation

    if [ -n "$archs" ]; then
        if [ -n "$cross" ]; then
            _arch="$DULGE_TARGET_MACHINE"
        elif [ -n "$DULGE_ARCH" ]; then
            _arch="$DULGE_ARCH"
        else
            _arch="$DULGE_MACHINE"
        fi
        set -f
        for f in ${archs}; do
            set +f
            nonegation=${f##\~*}
            f=${f#\~}
            case "${_arch}" in
                $f) match=1; break ;;
            esac
        done
        if [ -z "$nonegation" -a -n "$match" ] || [ -n "$nonegation" -a -z "$match" ]; then
            report_broken "${pkgname}-${version}_${revision}: this package cannot be built for ${_arch}.\n"
        fi
    fi
}

# Returns 1 if pkg is available in dulge repositories, 0 otherwise.
pkg_available() {
    local pkg="$1" cross="$2" pkgver

    if [ -n "$cross" ]; then
        pkgver=$($DULGE_QUERY_XCMD -R -ppkgver "${pkg}" 2>/dev/null)
    else
        pkgver=$($DULGE_QUERY_CMD -R -ppkgver "${pkg}" 2>/dev/null)
    fi

    if [ -z "$pkgver" ]; then
        return 0
    fi
    return 1
}

remove_pkg_autodeps() {
    local rval= tmplogf= errlogf= prevs=

    cd $DULGE_MASTERDIR || return 1
    msg_normal "${pkgver:-dulge-src}: removing autodeps, please wait...\n"
    tmplogf=$(mktemp) || exit 1
    errlogf=$(mktemp) || exit 1

    remove_pkg_cross_deps
    $DULGE_RECONFIGURE_CMD -a >> $tmplogf 2>&1
    prevs=$(stat_size $tmplogf)
    echo yes | $DULGE_REMOVE_CMD -Ryod 2>> $errlogf 1>> $tmplogf
    rval=$?
    while [ $rval -eq 0 ]; do
        local curs=$(stat_size $tmplogf)
        if [ $curs -eq $prevs ]; then
            break
        fi
        prevs=$curs
        echo yes | $DULGE_REMOVE_CMD -Ryod 2>> $errlogf 1>> $tmplogf
        rval=$?
    done

    if [ $rval -ne 0 ]; then
        msg_red "${pkgver:-dulge-src}: failed to remove autodeps: (returned $rval)\n"
        cat $tmplogf && rm -f $tmplogf
        cat $errlogf && rm -f $errlogf
        msg_error "${pkgver:-dulge-src}: cannot continue!\n"
    fi
    rm -f $tmplogf
    rm -f $errlogf
}

remove_pkg_wrksrc() {
    if [ -d "$wrksrc" ]; then
        msg_normal "$pkgver: cleaning build directory...\n"
        rm -rf "$wrksrc" 2>/dev/null || chmod -R +wX "$wrksrc" # Needed to delete Go Modules
        rm -rf "$wrksrc"
    fi
}

remove_pkg_statedir() {
    if [ -d "$DULGE_STATEDIR" ]; then
        rm -rf "$DULGE_STATEDIR"
    fi
}

remove_pkg() {
    local cross="$1" _destdir f

    [ -z $pkgname ] && msg_error "nonexistent package, aborting.\n"

    if [ -n "$cross" ]; then
        _destdir="$DULGE_DESTDIR/$DULGE_CROSS_TRIPLET"
    else
        _destdir="$DULGE_DESTDIR"
    fi

    [ ! -d ${_destdir} ] && return

    for f in ${sourcepkg} ${subpackages}; do
        if [ -d "${_destdir}/${f}-${version}" ]; then
            msg_normal "$f: removing files from destdir...\n"
            rm -rf ${_destdir}/${f}-${version}
        fi
        if [ -d "${_destdir}/${f}-dbg-${version}" ]; then
            msg_normal "$f: removing dbg files from destdir...\n"
            rm -rf ${_destdir}/${f}-dbg-${version}
        fi
        if [ -d "${_destdir}/${f}-32bit-${version}" ]; then
            msg_normal "$f: removing 32bit files from destdir...\n"
            rm -rf ${_destdir}/${f}-32bit-${version}
        fi
        rm -f ${DULGE_STATEDIR}/${f}_${cross}_subpkg_install_done
        rm -f ${DULGE_STATEDIR}/${f}_${cross}_prepkg_done
    done
    rm -f ${DULGE_STATEDIR}/${sourcepkg}_${cross}_install_done
    rm -f ${DULGE_STATEDIR}/${sourcepkg}_${cross}_pre_install_done
    rm -f ${DULGE_STATEDIR}/${sourcepkg}_${cross}_post_install_done
}
