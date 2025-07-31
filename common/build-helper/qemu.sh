if [ "$CROSS_BUILD" ]; then
	export QEMU_LD_PREFIX=${DULGE_CROSS_BASE}
	hostmakedepends+=" qemu-user-${DULGE_TARGET_QEMU_MACHINE/x86_64/amd64}"
fi

vtargetrun() {
	if [ "$CROSS_BUILD" ]; then
		"/usr/bin/qemu-${DULGE_TARGET_QEMU_MACHINE}" "$@"
	else
		"$@"
	fi
}
