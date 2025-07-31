# This hook generates a file ${DULGE_STATEDIR}/gitrev with the last
# commit sha1 (in short mode) for source pkg if DULGE_USE_GIT_REVS is enabled.

hook() {
	local GITREVS_FILE=${DULGE_STATEDIR}/gitrev

	# If DULGE_USE_GIT_REVS is disabled in conf file don't continue.
	if [ -z $DULGE_USE_GIT_REVS ]; then
		return
	fi
	# If the file exists don't regenerate it again.
	if [ -s ${GITREVS_FILE} ]; then
		return
	fi

	if [ -z "$DULGE_GIT_REVS" ]; then
		msg_error "BUG: DULGE_GIT_REVS is not set\n"
	fi

	cd $DULGE_SRCPKGDIR
	echo "${sourcepkg}:${DULGE_GIT_REVS}"
	echo "${sourcepkg}:${DULGE_GIT_REVS}" > $GITREVS_FILE
}
