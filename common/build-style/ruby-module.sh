#
# This helper is for templates installing ruby modules.
#

do_install() {
	local _vendorlibdir=$(ruby -e 'puts RbConfig::CONFIG["vendorlibdir"]')

	if [ "$DULGE_WORDSIZE" != "$DULGE_TARGET_WORDSIZE" ]; then
		_vendorlibdir="${_vendorlibdir//lib$DULGE_WORDSIZE/lib$DULGE_TARGET_WORDSIZE}"
	fi

	LANG=C ruby install.rb --destdir=${DESTDIR} --sitelibdir=${_vendorlibdir} ${make_install_args}
}
