# If DULGE_USE_BUILD_MTIME is enabled in conf file don't continue.
# only run this, if SOURCE_DATE_EPOCH isn't set.

if [ -z "$DULGE_GIT_CMD" ]; then
	if [ -z "$DULGE_USE_BUILD_MTIME" ] || [ -n "$DULGE_USE_GIT_REVS" ]; then
		msg_error "BUG: environment/setup: DULGE_GIT_CMD is not set\n"
	fi
fi

if [ -n "$DULGE_USE_BUILD_MTIME" ]; then
	unset SOURCE_DATE_EPOCH
elif [ -z "${SOURCE_DATE_EPOCH}" ]; then
	if [ -n "$IN_CHROOT" ]; then
		msg_error "dulge-src's BUG: SOURCE_DATE_EPOCH is undefined\n"
	fi
	# check if the template is under version control:
	if [ -n "$basepkg" -a -z "$($DULGE_GIT_CMD -C ${DULGE_SRCPKGDIR}/${basepkg} ls-files template)" ]; then
		export SOURCE_DATE_EPOCH="$(stat_mtime ${DULGE_SRCPKGDIR}/${basepkg}/template)"
	else
		export SOURCE_DATE_EPOCH=$($DULGE_GIT_CMD -C ${DULGE_DISTDIR} cat-file commit HEAD |
			sed -n '/^committer /{s/.*> \([0-9][0-9]*\) [-+][0-9].*/\1/p;q;}')
	fi
fi

# if DULGE_USE_GIT_REVS is enabled in conf file,
# compute DULGE_GIT_REVS to use in pkg hooks
if [ -z "$DULGE_USE_GIT_REVS" ]; then
	unset DULGE_GIT_REVS
elif [ -z "$DULGE_GIT_REVS" ]; then
	if [ -n "$IN_CHROOT" ]; then
		msg_error "dulge-src's BUG: DULGE_GIT_REVS is undefined\n"
	else
		export DULGE_GIT_REVS="$($DULGE_GIT_CMD -C "${DULGE_DISTDIR}" rev-parse --verify --short HEAD)"
	fi
fi
