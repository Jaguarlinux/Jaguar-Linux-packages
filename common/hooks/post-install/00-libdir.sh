# This hook removes the wordsize specific libdir symlink.

hook() {
	if [ "${pkgname}" != "base-files" ]; then
		rm -f ${PKGDESTDIR}/usr/lib${DULGE_TARGET_WORDSIZE}
	fi
}
