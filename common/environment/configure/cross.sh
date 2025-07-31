if [ -n "$CROSS_BUILD" ]; then
	CFLAGS+=" -I${DULGE_CROSS_BASE}/usr/include"
	CXXFLAGS+=" -I${DULGE_CROSS_BASE}/usr/include"
	LDFLAGS+=" -L${DULGE_CROSS_BASE}/usr/lib"
fi
