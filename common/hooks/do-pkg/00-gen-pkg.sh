# This hook generates a DULGE binary package from an installed package in destdir.

genpkg() {
	local pkgdir="$1" arch="$2" desc="$3" pkgver="$4" binpkg="$5" suffix="${6:-}"
	local _preserve _deps _shprovides _shrequires _gitrevs _provides _conflicts
	local _replaces _reverts _mutable_files _conf_files f
	local _pkglock="$pkgdir/${binpkg}.lock"

	if [ ! -d "${PKGDESTDIR}" ]; then
		msg_warn "$pkgver: cannot find pkg destdir... skipping!\n"
		return 0
	fi

	[ ! -d $pkgdir ] && mkdir -p $pkgdir

	while [ -f "$_pkglock" ]; do
		msg_warn "${pkgver}: binpkg is being created, waiting for 1s...\n"
		sleep 1
	done

	# Don't overwrite existing binpkgs by default, skip them.
	if [ -e $pkgdir/$binpkg ] && [ "$DULGE_PRESERVE_PKGS" ] && [ -z "$DULGE_BUILD_FORCEMODE" ]; then
		msg_normal "${pkgver}: skipping existing $binpkg pkg...\n"
		return 0
	fi

	# Lock binpkg
	trap "rm -f '$_pkglock'" ERR EXIT
	touch -f "$_pkglock"

	if [ ! -d $pkgdir ]; then
		mkdir -p $pkgdir
	fi
	cd $pkgdir

	_preserve=${preserve:+-p}
	if [ -s ${DULGE_STATEDIR}/${pkgname}${suffix}-rdeps ]; then
		_deps="$(<${DULGE_STATEDIR}/${pkgname}${suffix}-rdeps)"
	fi
	if [ -s ${DULGE_STATEDIR}/${pkgname}${suffix}-shlib-provides ]; then
		_shprovides="$(<${DULGE_STATEDIR}/${pkgname}${suffix}-shlib-provides)"
	fi
	if [ -s ${DULGE_STATEDIR}/${pkgname}${suffix}-provides ]; then
		_provides="$(<${DULGE_STATEDIR}/${pkgname}${suffix}-provides)"
	fi
	if [ -s ${DULGE_STATEDIR}/${pkgname}${suffix}-shlib-requires ]; then
		_shrequires="$(<${DULGE_STATEDIR}/${pkgname}${suffix}-shlib-requires)"
	fi
	if [ -s ${DULGE_STATEDIR}/gitrev ]; then
		_gitrevs="$(<${DULGE_STATEDIR}/gitrev)"
	fi

	# Stripping whitespaces
	local _conflicts="$(echo $conflicts)"
	local _replaces="$(echo $replaces)"
	local _reverts="$(echo $reverts)"
	local _mutable_files="$(echo $mutable_files)"
	local _conf_files="$(expand_destdir "$conf_files")"
	local _alternatives="$(echo $alternatives)"
	local _tags="$(echo $tags)"
	local _changelog="$(echo $changelog)"

	msg_normal "Creating $binpkg for repository $pkgdir ...\n"

	#
	# Create the DULGE binary package.
	#
	dulge-create \
		${_provides:+--provides "${_provides}"} \
		${_conflicts:+--conflicts "${_conflicts}"} \
		${_replaces:+--replaces "${_replaces}"} \
		${_reverts:+--reverts "${_reverts}"} \
		${_mutable_files:+--mutable-files "${_mutable_files}"} \
		${_deps:+--dependencies "${_deps}"} \
		${_conf_files:+--config-files "${_conf_files}"} \
		${PKG_BUILD_OPTIONS:+--build-options "${PKG_BUILD_OPTIONS}"} \
		${_gitrevs:+--source-revisions "${_gitrevs}"} \
		${_shprovides:+--shlib-provides "${_shprovides}"} \
		${_shrequires:+--shlib-requires "${_shrequires}"} \
		${_alternatives:+--alternatives "${_alternatives}"} \
		${_preserve:+--preserve} \
		${tags:+--tags "${tags}"} \
		${_changelog:+--changelog "${_changelog}"} \
		${DULGE_PKG_COMPTYPE:+--compression $DULGE_PKG_COMPTYPE} \
		--architecture ${arch} \
		--homepage "${homepage}" \
		--license "${license}" \
		--maintainer "${maintainer}" \
		--desc "${desc}" \
		--pkgver "${pkgver}" \
		--sourcepkg "${sourcepkg}" \
		--quiet \
		${PKGDESTDIR}
	rval=$?

	# Unlock binpkg
	rm -f "$_pkglock"
	trap - ERR EXIT

	if [ $rval -ne 0 ]; then
		rm -f $pkgdir/$binpkg
		msg_error "Failed to created binary package: $binpkg!\n"
	fi
}

hook() {
	local arch= binpkg= repo= _pkgver= _desc= _pkgn= _pkgv= _provides= \
		_replaces= _reverts= f= found_dbg_subpkg=

	arch=$DULGE_TARGET_MACHINE
	binpkg=${pkgver}.${arch}.dulge

	if [ -n "$repository" ]; then
		repo=$DULGE_REPOSITORY/$repository
	else
		repo=$DULGE_REPOSITORY
	fi

	genpkg ${repo} ${arch} "${short_desc}" ${pkgver} ${binpkg}

	for f in ${provides}; do
		_pkgn="$($DULGE_UHELPER_CMD getpkgname $f)"
		_pkgv="$($DULGE_UHELPER_CMD getpkgversion $f)"
		_provides+=" ${_pkgn}-32bit-${_pkgv}"
	done
	for f in ${replaces}; do
		_pkgn="$($DULGE_UHELPER_CMD getpkgdepname $f)"
		_pkgv="$($DULGE_UHELPER_CMD getpkgdepversion $f)"
		_replaces+=" ${_pkgn}-32bit${_pkgv}"
	done

	# Generate -dbg pkg.
	for f in ${subpackages}; do
		# If there's an explicit subpkg named ${pkgname}-dbg, don't generate
		# it automagically (required by linuxX.X).
		if [ "${sourcepkg}-dbg" = "$f" ]; then
			found_dbg_subpkg=1
			break
		fi
	done
	if [ -z "$found_dbg_subpkg" -a -d "${DULGE_DESTDIR}/${DULGE_CROSS_TRIPLET}/${pkgname}-dbg-${version}" ]; then
		source ${DULGE_COMMONDIR}/environment/setup-subpkg/subpkg.sh
		repo=$DULGE_REPOSITORY/debug
		_pkgver=${pkgname}-dbg-${version}_${revision}
		_desc="${short_desc} (debug files)"
		binpkg=${_pkgver}.${arch}.dulge
		PKGDESTDIR="${DULGE_DESTDIR}/${DULGE_CROSS_TRIPLET:+${DULGE_CROSS_TRIPLET}/}${pkgname}-dbg-${version}"
		genpkg ${repo} ${arch} "${_desc}" ${_pkgver} ${binpkg} -dbg
	fi
	# Generate 32bit pkg.
	if [ "$DULGE_TARGET_MACHINE" != "i686" ]; then
		return
	fi
	if [ -d "${DULGE_DESTDIR}/${pkgname}-32bit-${version}" ]; then
		source ${DULGE_COMMONDIR}/environment/setup-subpkg/subpkg.sh
		if [ -n "$repository" ]; then
			repo=$DULGE_REPOSITORY/multilib/$repository
		else
			repo=$DULGE_REPOSITORY/multilib
		fi
		_pkgver=${pkgname}-32bit-${version}_${revision}
		_desc="${short_desc} (32bit)"
		binpkg=${_pkgver}.x86_64.dulge
		PKGDESTDIR="${DULGE_DESTDIR}/${pkgname}-32bit-${version}"
		[ -n "${_provides}" ] && export provides="${_provides}"
		[ -n "${_replaces}" ] && export replaces="${_replaces}"
		genpkg ${repo} x86_64 "${_desc}" ${_pkgver} ${binpkg} -32bit
	fi
}
