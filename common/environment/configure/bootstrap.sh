if [ -z "$CHROOT_READY" ]; then
	CFLAGS+=" -isystem ${DULGE_MASTERDIR}/usr/include"
	LDFLAGS+=" -L${DULGE_MASTERDIR}/usr/lib -Wl,-rpath-link=${DULGE_MASTERDIR}/usr/lib"
fi
