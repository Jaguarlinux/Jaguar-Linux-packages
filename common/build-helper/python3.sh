# fix building non-pure-python modules on cross
if [ -n "$CROSS_BUILD" ]; then
	export PYPREFIX="$DULGE_CROSS_BASE"
	export CFLAGS+=" -I${DULGE_CROSS_BASE}/${py3_inc} -I${DULGE_CROSS_BASE}/usr/include"
	export CXXFLAGS+=" -I${DULGE_CROSS_BASE}/${py3_inc} -I${DULGE_CROSS_BASE}/usr/include"
	export LDFLAGS+=" -L${DULGE_CROSS_BASE}/${py3_lib} -L${DULGE_CROSS_BASE}/usr/lib"
	export CC="${DULGE_CROSS_TRIPLET}-gcc -pthread $CFLAGS $LDFLAGS"
	export CXX="${DULGE_CROSS_TRIPLET}-g++ -pthread $CXXFLAGS $LDFLAGS"
	export LDSHARED="${CC} -shared $LDFLAGS"
	export PYTHON_CONFIG="${DULGE_CROSS_BASE}/usr/bin/python3-config"
	export PYTHONPATH="${DULGE_CROSS_BASE}/${py3_lib}"
	for f in ${DULGE_CROSS_BASE}/${py3_lib}/_sysconfigdata_*; do
		[ -f "$f" ] || continue
		f=${f##*/}
		_PYTHON_SYSCONFIGDATA_NAME=${f%.py}
	done
	[ -n "$_PYTHON_SYSCONFIGDATA_NAME" ] && export _PYTHON_SYSCONFIGDATA_NAME
fi
