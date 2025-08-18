# vim: set ts=4 sw=4 et:

install_base_chroot() {
    [ "$CHROOT_READY" ] && return
    if [ "$1" = "bootstrap" ]; then
        unset DULGE_TARGET_PKG DULGE_INSTALL_ARGS
    else
        DULGE_TARGET_PKG="$1"
    fi
    # binary bootstrap
    msg_normal "dulge-src: installing base-chroot...\n"
    # DULGE_TARGET_PKG == arch
    if [ "$DULGE_TARGET_PKG" ]; then
        _bootstrap_arch="env DULGE_TARGET_ARCH=$DULGE_TARGET_PKG"
    fi
    (export DULGE_MACHINE=$DULGE_TARGET_PKG DULGE_ARCH=$DULGE_TARGET_PKG; chroot_sync_repodata)
    ${_bootstrap_arch} $DULGE_INSTALL_CMD ${DULGE_INSTALL_ARGS} -y base-chroot
    if [ $? -ne 0 ]; then
        msg_error "dulge-src: failed to install base-chroot!\n"
    fi
    # Reconfigure base-files to create dirs/symlinks.
    if dulge-query -r $DULGE_MASTERDIR base-files &>/dev/null; then
        DULGE_ARCH=$DULGE_TARGET_PKG dulge-reconfigure -r $DULGE_MASTERDIR -f base-files &>/dev/null
    fi

    msg_normal "dulge-src: installed base-chroot successfully!\n"
    chroot_prepare $DULGE_TARGET_PKG || msg_error "dulge-src: failed to initialize chroot!\n"
    chroot_check
    chroot_handler clean
}

reconfigure_base_chroot() {
    local statefile="$DULGE_MASTERDIR/.dulge_chroot_configured"
    local pkgs="glibc-locales ca-certificates"
    [ -z "$IN_CHROOT" -o -e $statefile ] && return 0
    # Reconfigure ca-certificates.
    msg_normal "dulge-src: reconfiguring base-chroot...\n"
    for f in ${pkgs}; do
        if dulge-query -r $DULGE_MASTERDIR $f &>/dev/null; then
            dulge-reconfigure -r $DULGE_MASTERDIR -f $f
        fi
    done
    touch -f $statefile
}

update_base_chroot() {
    local keep_all_force=$1
    [ -z "$CHROOT_READY" ] && return
    msg_normal "dulge-src: updating software in $DULGE_MASTERDIR masterdir...\n"
    # no need to sync repodata, chroot_sync_repodata() does it for us.
    if $(${DULGE_INSTALL_CMD} ${DULGE_INSTALL_ARGS} -nu|grep -q dulge); then
        ${DULGE_INSTALL_CMD} ${DULGE_INSTALL_ARGS} -yu dulge || msg_error "dulge-src: failed to update dulge!\n"
    fi
    ${DULGE_INSTALL_CMD} ${DULGE_INSTALL_ARGS} -yu || msg_error "dulge-src: failed to update base-chroot!\n"
    msg_normal "dulge-src: cleaning up $DULGE_MASTERDIR masterdir...\n"
    [ -z "$DULGE_KEEP_ALL" -a -z "$DULGE_SKIP_DEPS" ] && remove_pkg_autodeps
    [ -z "$DULGE_KEEP_ALL" -a -z "$keep_all_force" ] && rm -rf $DULGE_MASTERDIR/builddir $DULGE_MASTERDIR/destdir
}

# FIXME: $DULGE_FFLAGS is not set when chroot_init() is run
# It is set in common/build-profiles/bootstrap.sh but lost somewhere?
chroot_init() {
    mkdir -p $DULGE_MASTERDIR/etc/dulge

    : ${DULGE_CONFIG_FILE:=/dev/null}
    cat > $DULGE_MASTERDIR/etc/dulge/dulge-src.conf <<_EOF
# Generated configuration file by dulge-src, DO NOT EDIT!
$(grep -E '^DULGE_.*' "$DULGE_CONFIG_FILE")
DULGE_MASTERDIR=/
DULGE_CFLAGS="$DULGE_CFLAGS"
DULGE_CXXFLAGS="$DULGE_CXXFLAGS"
DULGE_FFLAGS="$DULGE_FFLAGS"
DULGE_CPPFLAGS="$DULGE_CPPFLAGS"
DULGE_LDFLAGS="$DULGE_LDFLAGS"
DULGE_HOSTDIR=/host
# End of configuration file.
_EOF

    # Create custom script to start the chroot bash shell.
    cat > $DULGE_MASTERDIR/bin/dulge-shell <<_EOF
#!/bin/sh

DULGE_SRC_VERSION="$DULGE_SRC_VERSION"

. /etc/dulge/dulge-src.conf

PATH=/jaguar-packages:/usr/bin

exec env -i -- SHELL=/bin/sh PATH="\$PATH" DISTCC_HOSTS="\$DULGE_DISTCC_HOSTS" DISTCC_DIR="/host/distcc" \
    ${DULGE_ARCH+DULGE_ARCH=$DULGE_ARCH} ${DULGE_CHECK_PKGS+DULGE_CHECK_PKGS=$DULGE_CHECK_PKGS} \
    CCACHE_DIR="/host/ccache" IN_CHROOT=1 LC_COLLATE=C LANG=en_US.UTF-8 TERM=linux HOME="/tmp" \
    PS1="[\u@$DULGE_MASTERDIR \W]$ " /bin/bash +h "\$@"
_EOF

    chmod 755 $DULGE_MASTERDIR/bin/dulge-shell
    cp -f /etc/resolv.conf $DULGE_MASTERDIR/etc
    return 0
}

chroot_prepare() {
    local f=

    if [ -f $DULGE_MASTERDIR/.dulge_chroot_init ]; then
        return 0
    elif [ ! -f $DULGE_MASTERDIR/bin/bash ]; then
        msg_error "Bootstrap not installed in $DULGE_MASTERDIR, can't continue.\n"
    fi

    # Some software expects /etc/localtime to be a symbolic link it can read to
    # determine the name of the time zone, so set up the expected link
    # structure.
    ln -sf ../usr/share/zoneinfo/UTC $DULGE_MASTERDIR/etc/localtime

    for f in dev sys tmp proc host boot; do
        [ ! -d $DULGE_MASTERDIR/$f ] && mkdir -p $DULGE_MASTERDIR/$f
    done

    # Copy /etc/passwd and /etc/group from base-files.
    cp -f $DULGE_SRCPKGDIR/base-files/files/passwd $DULGE_MASTERDIR/etc
    echo "$(whoami):x:$(id -u):$(id -g):$(whoami) user:/tmp:/bin/dulge-shell" \
        >> $DULGE_MASTERDIR/etc/passwd
    cp -f $DULGE_SRCPKGDIR/base-files/files/group $DULGE_MASTERDIR/etc
    echo "$(whoami):x:$(id -g):" >> $DULGE_MASTERDIR/etc/group

    # Copy /etc/hosts from base-files.
    cp -f $DULGE_SRCPKGDIR/base-files/files/hosts $DULGE_MASTERDIR/etc

    # Prepare default locale: en_US.UTF-8.
    if [ -s ${DULGE_MASTERDIR}/etc/default/libc-locales ]; then
        printf '%s\n' \
            'C.UTF-8 UTF-8' \
            'en_US.UTF-8 UTF-8' \
            >> ${DULGE_MASTERDIR}/etc/default/libc-locales
    fi

    touch -f $DULGE_MASTERDIR/.dulge_chroot_init
    [ -n "$1" ] && echo $1 >> $DULGE_MASTERDIR/.dulge_chroot_init

    return 0
}

chroot_handler() {
    local action="$1" pkg="$2" rv=0 arg= _envargs=

    [ -z "$action" -a -z "$pkg" ] && return 1

    if [ -n "$IN_CHROOT" -o -z "$CHROOT_READY" ]; then
        return 0
    fi
    if [ ! -d $DULGE_MASTERDIR/jaguar-packages ]; then
        mkdir -p $DULGE_MASTERDIR/jaguar-packages
    fi

    case "$action" in
        fetch|extract|patch|configure|build|check|install|pkg|bootstrap-update|chroot|clean)
            chroot_prepare || return $?
            chroot_init || return $?
            ;;
    esac

    if [ "$action" = "chroot" ]; then
        $DULGE_COMMONDIR/chroot-style/${DULGE_CHROOT_CMD:=uunshare}.sh \
            $DULGE_MASTERDIR $DULGE_DISTDIR "$DULGE_HOSTDIR" "$DULGE_CHROOT_CMD_ARGS" /bin/dulge-shell
        rv=$?
    else
        env -i -- PATH="/usr/bin:$PATH" SHELL=/bin/sh \
            HOME=/tmp IN_CHROOT=1 LC_COLLATE=C LANG=en_US.UTF-8 \
            ${http_proxy:+http_proxy="${http_proxy}"} \
            ${https_proxy:+https_proxy="${https_proxy}"} \
            ${ftp_proxy:+ftp_proxy="${ftp_proxy}"} \
            ${all_proxy:+all_proxy="${all_proxy}"} \
            ${no_proxy:+no_proxy="${no_proxy}"} \
            ${HTTP_PROXY:+HTTP_PROXY="${HTTP_PROXY}"} \
            ${HTTPS_PROXY:+HTTPS_PROXY="${HTTPS_PROXY}"} \
            ${FTP_PROXY:+FTP_PROXY="${FTP_PROXY}"} \
            ${SOCKS_PROXY:+SOCKS_PROXY="${SOCKS_PROXY}"} \
            ${NO_PROXY:+NO_PROXY="${NO_PROXY}"} \
            ${HTTP_PROXY_AUTH:+HTTP_PROXY_AUTH="${HTTP_PROXY_AUTH}"} \
            ${FTP_RETRIES:+FTP_RETRIES="${FTP_RETRIES}"} \
            SOURCE_DATE_EPOCH="$SOURCE_DATE_EPOCH" \
            DULGE_GIT_REVS="$DULGE_GIT_REVS" \
            DULGE_ALLOW_CHROOT_BREAKOUT="$DULGE_ALLOW_CHROOT_BREAKOUT" \
            ${DULGE_ALT_REPOSITORY:+DULGE_ALT_REPOSITORY=$DULGE_ALT_REPOSITORY} \
            $DULGE_COMMONDIR/chroot-style/${DULGE_CHROOT_CMD:=uunshare}.sh \
            $DULGE_MASTERDIR $DULGE_DISTDIR "$DULGE_HOSTDIR" "$DULGE_CHROOT_CMD_ARGS" \
            /jaguar-packages/dulge-src $DULGE_OPTIONS $action $pkg
        rv=$?
    fi

    return $rv
}

chroot_sync_repodata() {
    local f= hostdir= confdir= crossconfdir=

    # always start with an empty dulge.d
    confdir=$DULGE_MASTERDIR/etc/dulge.d
    crossconfdir=$DULGE_MASTERDIR/$DULGE_CROSS_BASE/etc/dulge.d

    [ -d $confdir ] && rm -rf $confdir
    [ -d $crossconfdir ] && rm -rf $crossconfdir

    if [ -d $DULGE_DISTDIR/etc/dulge.d/custom ]; then
        mkdir -p $confdir $crossconfdir
        cp -f $DULGE_DISTDIR/etc/dulge.d/custom/*.conf $confdir
        cp -f $DULGE_DISTDIR/etc/dulge.d/custom/*.conf $crossconfdir
    fi
    if [ "$CHROOT_READY" ]; then
        hostdir=/host
    else
        hostdir=$DULGE_HOSTDIR
    fi

    # Update dulge alternative repository if set.
    mkdir -p $confdir
    if [ -n "$DULGE_ALT_REPOSITORY" ]; then
        cat <<- ! > $confdir/00-repository-alt-local.conf
		repository=$hostdir/binpkgs/${DULGE_ALT_REPOSITORY}/bootstrap
		repository=$hostdir/binpkgs/${DULGE_ALT_REPOSITORY}
		repository=$hostdir/binpkgs/${DULGE_ALT_REPOSITORY}/nonfree
		repository=$hostdir/binpkgs/${DULGE_ALT_REPOSITORY}/debug
		!
        if [ "$DULGE_MACHINE" = "x86_64" ]; then
            cat <<- ! >> $confdir/00-repository-alt-local.conf
			repository=$hostdir/binpkgs/${DULGE_ALT_REPOSITORY}/multilib/bootstrap
			repository=$hostdir/binpkgs/${DULGE_ALT_REPOSITORY}/multilib
			repository=$hostdir/binpkgs/${DULGE_ALT_REPOSITORY}/multilib/nonfree
			!
        fi
    else
        rm -f $confdir/00-repository-alt-local.conf
    fi

    # Disable 00-repository-main.conf from share/dulge.d (part of dulge)
    ln -s /dev/null $confdir/00-repository-main.conf

    # Generate dulge.d(5) configuration files for repositories
    sed -e "s,/host,$hostdir,g" ${DULGE_DISTDIR}/etc/dulge.d/repos-local.conf \
        > $confdir/10-repository-local.conf

    # Install multilib conf for local repos if it exists for the architecture
    if [ -s "${DULGE_DISTDIR}/etc/dulge.d/repos-local-${DULGE_MACHINE}-multilib.conf" ]; then
        install -Dm644 ${DULGE_DISTDIR}/etc/dulge.d/repos-local-${DULGE_MACHINE}-multilib.conf \
            $confdir/12-repository-local-multilib.conf
    fi

    # mirror_sed is a sed script: nop by default
    local mirror_sed
    if [ -n "$DULGE_MIRROR" ]; then
        # when DULGE_MIRROR is set, mirror_sed rewrites remote repos
        mirror_sed="s|^repository=http.*/current|repository=${DULGE_MIRROR}|"
    fi

    if [ "$DULGE_SKIP_REMOTEREPOS" ]; then
        rm -f $confdir/*remote*
    else
        if [ -s "${DULGE_DISTDIR}/etc/dulge.d/repos-remote-${DULGE_MACHINE}.conf" ]; then
            # If per-architecture base remote repo config exists, use that
            sed -e "$mirror_sed" ${DULGE_DISTDIR}/etc/dulge.d/repos-remote-${DULGE_MACHINE}.conf \
                > $confdir/20-repository-remote.conf
        else
            # Otherwise use generic base for musl or glibc
            local suffix=
            case "$DULGE_MACHINE" in
                *-musl) suffix="-musl";;
            esac
            sed -e "$mirror_sed" ${DULGE_DISTDIR}/etc/dulge.d/repos-remote${suffix}.conf \
                > $confdir/20-repository-remote.conf
        fi
        # Install multilib conf for remote repos if it exists for the architecture
        if [ -s "${DULGE_DISTDIR}/etc/dulge.d/repos-remote-${DULGE_MACHINE}-multilib.conf" ]; then
            sed -e "$mirror_sed" ${DULGE_DISTDIR}/etc/dulge.d/repos-remote-${DULGE_MACHINE}-multilib.conf \
                > $confdir/22-repository-remote-multilib.conf
        fi
    fi

    echo "syslog=false" > $confdir/00-dulge-src.conf
    echo "staging=true" >> $confdir/00-dulge-src.conf

    # Copy host repos to the cross root.
    if [ -n "$DULGE_CROSS_BUILD" ]; then
        rm -rf $DULGE_MASTERDIR/$DULGE_CROSS_BASE/etc/dulge.d
        mkdir -p $DULGE_MASTERDIR/$DULGE_CROSS_BASE/etc/dulge.d
        # Disable 00-repository-main.conf from share/dulge.d (part of dulge)
        ln -s /dev/null $DULGE_MASTERDIR/$DULGE_CROSS_BASE/etc/dulge.d/00-repository-main.conf
        # copy dulge.d files from host for local repos
        cp ${DULGE_MASTERDIR}/etc/dulge.d/*local*.conf \
            $DULGE_MASTERDIR/$DULGE_CROSS_BASE/etc/dulge.d
        if [ "$DULGE_SKIP_REMOTEREPOS" ]; then
            rm -f $crossconfdir/*remote*
        else
            # Same general logic as above, just into cross root, and no multilib
            if [ -s "${DULGE_DISTDIR}/etc/dulge.d/repos-remote-${DULGE_TARGET_MACHINE}.conf" ]; then
                sed -e "$mirror_sed" ${DULGE_DISTDIR}/etc/dulge.d/repos-remote-${DULGE_TARGET_MACHINE}.conf \
                    > $crossconfdir/20-repository-remote.conf
            else
                local suffix=
                case "$DULGE_TARGET_MACHINE" in
                    *-musl) suffix="-musl"
                esac
                sed -e "$mirror_sed" ${DULGE_DISTDIR}/etc/dulge.d/repos-remote${suffix}.conf \
                    > $crossconfdir/20-repository-remote.conf
            fi
        fi

        echo "syslog=false" > $crossconfdir/00-dulge-src.conf
        echo "staging=true" >> $crossconfdir/00-dulge-src.conf
    fi


    # Copy dulge repository keys to the masterdir.
    mkdir -p $DULGE_MASTERDIR/var/db/dulge/keys
    cp -f $DULGE_COMMONDIR/repo-keys/*.plist $DULGE_MASTERDIR/var/db/dulge/keys
    if [ -n "$(shopt -s nullglob; echo "$DULGE_DISTDIR"/etc/repo-keys/*.plist)" ]; then
        cp -f "$DULGE_DISTDIR"/etc/repo-keys/*.plist "$DULGE_MASTERDIR"/var/db/dulge/keys
    fi

    # Make sure to sync index for remote repositories.
    if [ -z "$DULGE_SKIP_REMOTEREPOS" ]; then
        msg_normal "dulge-src: updating repositories for host ($DULGE_MACHINE)...\n"
        $DULGE_INSTALL_CMD $DULGE_INSTALL_ARGS -S
    fi

    if [ -n "$DULGE_CROSS_BUILD" ]; then
        # Copy host keys to the target rootdir.
        mkdir -p $DULGE_MASTERDIR/$DULGE_CROSS_BASE/var/db/dulge/keys
        cp $DULGE_MASTERDIR/var/db/dulge/keys/*.plist \
            $DULGE_MASTERDIR/$DULGE_CROSS_BASE/var/db/dulge/keys
        # Make sure to sync index for remote repositories.
        if [ -z "$DULGE_SKIP_REMOTEREPOS" ]; then
            msg_normal "dulge-src: updating repositories for target ($DULGE_TARGET_MACHINE)...\n"
            env -- DULGE_TARGET_ARCH=$DULGE_TARGET_MACHINE \
                $DULGE_INSTALL_CMD $DULGE_INSTALL_ARGS -r $DULGE_MASTERDIR/$DULGE_CROSS_BASE -S
        fi
    fi

    return 0
}
