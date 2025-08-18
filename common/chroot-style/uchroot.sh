#!/bin/sh
#
# This chroot script uses dulge-uchroot(1).
#
readonly MASTERDIR="$1"
readonly DISTDIR="$2"
readonly HOSTDIR="$3"
readonly EXTRA_ARGS="$4"
readonly CMD="$5"
shift 5

msg_red() {
	# error messages in bold/red
	[ -n "$NOCOLORS" ] || printf >&2 "\033[1m\033[31m"
	printf "=> ERROR: %s\\n" "$@" >&2
	[ -n "$NOCOLORS" ] || printf >&2 "\033[m"
}

readonly DULGE_UCHROOT_CMD="$(command -v dulge-uchroot 2>/dev/null)"

if [ -z "$DULGE_UCHROOT_CMD" ]; then
	msg_red "could not find dulge-uchroot"
	exit 1
fi

if ! [ -x "$DULGE_UCHROOT_CMD" ]; then
	msg_red "dulge-uchroot is not executable. Are you in the $(stat -c %G "$DULGE_UCHROOT_CMD") group?"
	exit 1
fi

if [ -z "$MASTERDIR" ] || [ -z "$DISTDIR" ]; then
	msg_red "$0: MASTERDIR/DISTDIR not set"
	exit 1
fi

exec dulge-uchroot $EXTRA_ARGS -b $DISTDIR:/jaguar-packages ${HOSTDIR:+-b $HOSTDIR:/host} -- $MASTERDIR $CMD $@
