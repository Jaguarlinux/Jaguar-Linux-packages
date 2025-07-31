# This hook displays resolved dependencies for a pkg.

hook() {
	if [ -e "${DULGE_STATEDIR}/${pkgname}-rdeps" ]; then
		echo "   $(cat "${DULGE_STATEDIR}/${pkgname}-rdeps")"
	fi
}
