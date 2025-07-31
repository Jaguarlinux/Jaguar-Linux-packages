hook() {
	local destdir32=${DULGE_DESTDIR}/${pkgname}-32bit-${version}

	# By default always enabled unless "lib32disabled" is set.
	if [ -n "$lib32disabled" ]; then
		return
	fi

	# This hook will only work when building for x86.
	if [ "$DULGE_TARGET_MACHINE" != "i686" ]; then
		return
	fi

	if [ ! -d ${destdir32} ]; then
		return
	fi

	# If the rdeps file exist (runtime deps), copy and then modify it for
	# 32bit dependencies.
	trap - ERR

	: > ${DULGE_STATEDIR}/${pkgname}-32bit-rdeps

	if [ -s "${DULGE_STATEDIR}/${pkgname}-rdeps" ]; then
		if [ -n "$lib32depends" ]; then
			_deps="${lib32depends}"
		else
			_deps="$(<${DULGE_STATEDIR}/${pkgname}-rdeps)"
		fi
		for f in ${_deps}; do
			unset found pkgn pkgv _shprovides

			pkgn="$($DULGE_UHELPER_CMD getpkgdepname $f)"
			if [ -z "${pkgn}" ]; then
				pkgn="$($DULGE_UHELPER_CMD getpkgname $f)"
				if [ -z "${pkgn}" ]; then
					msg_error "$pkgver: invalid dependency $f\n"
				fi
				pkgv="-$($DULGE_UHELPER_CMD getpkgversion ${f})"
			else
				pkgv="$($DULGE_UHELPER_CMD getpkgdepversion ${f})"
			fi
			# If dependency is a development pkg switch it to 32bit.
			if [[ $pkgn == *-devel ]]; then
				echo "   RDEP: $f -> ${pkgn}-32bit${pkgv} (development)"
				printf "${pkgn}-32bit${pkgv} " >> ${DULGE_STATEDIR}/${pkgname}-32bit-rdeps
				continue
			fi
			# If dependency does not have "shlib-provides" do not
			# change it to 32bit.
			for x in ${subpackages}; do
				if [ "$x" = "$pkgn" ]; then
					found=1
					break
				fi
			done
			if [ -z "$found" ]; then
				# Dependency is not a subpkg, check shlib-provides
				# via binpkgs.
				_shprovides="$($DULGE_QUERY_CMD -R --property=shlib-provides "$pkgn")"
				if [ -n "${_shprovides}" ]; then
					echo "   RDEP: $f -> ${pkgn}-32bit${pkgv} (shlib-provides)"
					printf "${pkgn}-32bit${pkgv} " >> ${DULGE_STATEDIR}/${pkgname}-32bit-rdeps
				else
					echo "   RDEP: $f -> ${pkgn}${pkgv} (no shlib-provides)"
					printf "${pkgn}${pkgv} " >> ${DULGE_STATEDIR}/${pkgname}-32bit-rdeps
				fi
			else
				if [ -s "${DULGE_STATEDIR}/${pkgn}-shlib-provides" ]; then
					# Dependency is a subpkg; check if it provides any shlib
					# and convert to 32bit if true.
					echo "   RDEP: $f -> ${pkgn}-32bit${pkgv} (subpkg, shlib-provides)"
					printf "${pkgn}-32bit${pkgv} " >> ${DULGE_STATEDIR}/${pkgname}-32bit-rdeps
				else
					echo "   RDEP: $f -> ${pkgn}${pkgv} (subpkg, no shlib-provides)"
					printf "${pkgn}${pkgv} " >> ${DULGE_STATEDIR}/${pkgname}-32bit-rdeps
				fi
			fi
		done
	fi
	# If it's a development pkg add a dependency to the 64bit pkg.
	if [[ $pkgn == *-devel ]]; then
		echo "   RDEP: ${pkgver}"
		printf "${pkgver} " >> ${DULGE_STATEDIR}/${pkgname}-32bit-rdeps
	fi
	printf "\n" >> ${DULGE_STATEDIR}/${pkgname}-32bit-rdeps
}
