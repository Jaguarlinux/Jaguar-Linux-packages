# This hook fixes the wrong install path of 'gir' files
# when cross building packages. It's a workaround and
# not a proper fix. Remove it once the root cause of the
# problem is fixed.

hook() {
	[ -z "$CROSS_BUILD" ] && return
	vmkdir usr/${DULGE_CROSS_TRIPLET}
	ln -sf ".." "${PKGDESTDIR}/usr/${DULGE_CROSS_TRIPLET}/usr"
}
