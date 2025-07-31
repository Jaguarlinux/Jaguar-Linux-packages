# This snippet setups pkg-config vars.

if [ -z "$CHROOT_READY" ]; then
	export PKG_CONFIG_PATH="${DULGE_MASTERDIR}/usr/lib/pkgconfig:${DULGE_MASTERDIR}/usr/share/pkgconfig"
fi
