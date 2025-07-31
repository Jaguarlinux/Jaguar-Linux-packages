# This hook creates the wordsize specific libdir symlink.

hook() {
	if [ -L ${PKGDESTDIR}/usr/lib${DULGE_TARGET_WORDSIZE} ]; then
		return 0
	elif [ "${pkgname}" != "base-files" ]; then
		vmkdir usr/lib
		ln -sf lib ${PKGDESTDIR}/usr/lib${DULGE_TARGET_WORDSIZE}
	fi
}
