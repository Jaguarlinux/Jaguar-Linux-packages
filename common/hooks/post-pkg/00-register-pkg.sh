# This hook registers a DULGE binary package into the specified local repository.

registerpkg() {
	local repo="$1" pkg="$2" arch="$3"

	if [ ! -f ${repo}/${pkg} ]; then
		msg_error "Nonexistent binary package ${repo}/${pkg}!\n"
	fi

	printf "%s:%s:%s\n" "${arch}" "${repo}" "${pkg}" >> "${DULGE_STATEDIR}/.${sourcepkg}_register_pkg"
}

hook() {
	local arch= binpkg= pkgdir=

	if [ -n "$repository" ]; then
		pkgdir=$DULGE_REPOSITORY/$repository
	else
		pkgdir=$DULGE_REPOSITORY
	fi
	arch=$DULGE_TARGET_MACHINE
	binpkg=${pkgver}.${arch}.dulge
	binpkg32=${pkgname}-32bit-${version}_${revision}.x86_64.dulge
	binpkg_dbg=${pkgname}-dbg-${version}_${revision}.${arch}.dulge

	# Register binpkg.
	if [ -f ${pkgdir}/${binpkg} ]; then
		registerpkg ${pkgdir} ${binpkg}
	fi

	# Register -dbg binpkg if it exists.
	pkgdir=$DULGE_REPOSITORY/debug
	PKGDESTDIR="${DULGE_DESTDIR}/${DULGE_CROSS_TRIPLET:+${DULGE_CROSS_TRIPLET}/}${pkgname}-dbg-${version}"
	if [ -d ${PKGDESTDIR} -a -f ${pkgdir}/${binpkg_dbg} ]; then
		registerpkg ${pkgdir} ${binpkg_dbg}
	fi

	# Register 32bit binpkg if it exists.
	if [ "$DULGE_TARGET_MACHINE" != "i686" ]; then
		return
	fi
	if [ -n "$repository" ]; then
		pkgdir=$DULGE_REPOSITORY/multilib/$repository
	else
		pkgdir=$DULGE_REPOSITORY/multilib
	fi
	PKGDESTDIR="${DULGE_DESTDIR}/${pkgname}-32bit-${version}"
	if [ -d ${PKGDESTDIR} -a -f ${pkgdir}/${binpkg32} ]; then
		registerpkg ${pkgdir} ${binpkg32} x86_64
	fi
}
