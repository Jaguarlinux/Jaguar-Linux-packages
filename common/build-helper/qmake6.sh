# This build-helper sets up qmake’s cross environment
# in cases the build-style is mixed,
# e.g. when in a gnu-configure style the configure
# script calls qmake or a makefile in a gnu-makefile style,
# respectively.

if [ "$CROSS_BUILD" ]; then
	mkdir -p "${DULGE_WRAPPERDIR}/target-spec/linux-g++"
	cat > "${DULGE_WRAPPERDIR}/target-spec/linux-g++/qmake.conf" <<_EOF
MAKEFILE_GENERATOR      = UNIX
CONFIG                 += incremental no_qt_rpath
QMAKE_INCREMENTAL_STYLE = sublib

include(/usr/lib/qt6/mkspecs/common/linux.conf)
include(/usr/lib/qt6/mkspecs/common/gcc-base-unix.conf)
include(/usr/lib/qt6/mkspecs/common/g++-unix.conf)

QMAKE_TARGET_CONFIG     = ${DULGE_CROSS_BASE}/usr/lib/qt6/mkspecs/qconfig.pri
QMAKE_TARGET_MODULE     = ${DULGE_CROSS_BASE}/usr/lib/qt6/mkspecs/qmodule.pri
QMAKEMODULES            = ${DULGE_CROSS_BASE}/usr/lib/qt6/mkspecs/modules
QMAKE_CC                = ${CC}
QMAKE_CXX               = ${CXX}
QMAKE_LINK              = ${CXX}
QMAKE_LINK_C            = ${CC}
QMAKE_LINK_SHLIB        = ${CXX}

QMAKE_AR                = ${DULGE_CROSS_TRIPLET}-gcc-ar cqs
QMAKE_OBJCOPY           = ${OBJCOPY}
QMAKE_NM                = ${NM} -P
QMAKE_STRIP             = ${STRIP}

QMAKE_CFLAGS            = ${CFLAGS}
QMAKE_CXXFLAGS          = ${CXXFLAGS}
QMAKE_LFLAGS            = ${LDFLAGS}
load(qt_config)
_EOF
	echo "#include \"${DULGE_CROSS_BASE}/usr/lib/qt6/mkspecs/linux-g++/qplatformdefs.h\"" > "${DULGE_WRAPPERDIR}/target-spec/linux-g++/qplatformdefs.h"

	cat > "${DULGE_WRAPPERDIR}/qt.conf" <<_EOF
[Paths]
Sysroot=${DULGE_CROSS_BASE}
Prefix=${DULGE_CROSS_BASE}/usr
ArchData=${DULGE_CROSS_BASE}/usr/lib/qt6
Data=${DULGE_CROSS_BASE}/usr/share/qt6
Documentation=${DULGE_CROSS_BASE}/usr/share/doc/qt6
Headers=${DULGE_CROSS_BASE}/usr/include/qt6
Libraries=${DULGE_CROSS_BASE}/usr/lib
LibraryExecutables=/usr/lib/qt6/libexec
Binaries=/usr/lib/qt6/bin
Tests=${DULGE_CROSS_BASE}/usr/tests
Plugins=/usr/lib/qt6/plugins
Imports=${DULGE_CROSS_BASE}/usr/lib/qt6/imports
Qml2Imports=${DULGE_CROSS_BASE}/usr/lib/qt6/qml
Translations=${DULGE_CROSS_BASE}/usr/share/qt6/translations
Settings=${DULGE_CROSS_BASE}/etc/xdg
Examples=${DULGE_CROSS_BASE}/usr/lib/qt6/examples
HostPrefix=/usr
HostData=/usr/lib/qt6
HostBinaries=/usr/lib/qt6/bin
HostLibraries=/usr/lib
HostLibraryExecutables=/usr/lib/qt6/libexec
Spec=linux-g++
TargetSpec=$DULGE_WRAPPERDIR/target-spec/linux-g++
_EOF

	# create the qmake-wrapper here because it only
	# makes sense together with the qmake build-helper
	# and not to interfere with e.g. the qmake build-style
	#
	#   + base flags will be picked up from QMAKE_{C,CXX,LD}FLAGS
	#   + hardening flags will be picked up from environment variables
        cat > "${DULGE_WRAPPERDIR}/qmake" <<_EOF
#!/bin/sh
exec /usr/lib/qt6/bin/qmake "\$@" -qtconf "${DULGE_WRAPPERDIR}/qt.conf" \\
	QMAKE_CFLAGS+="\${CFLAGS}" \\
	QMAKE_CXXFLAGS+="\${CXXFLAGS}" \\
	QMAKE_LFLAGS+="\${LDFLAGS}"
_EOF
else
        cat > "${DULGE_WRAPPERDIR}/qmake" <<_EOF
#!/bin/sh
exec /usr/lib/qt6/bin/qmake \
	"\$@" \
	PREFIX=/usr \
	QT_INSTALL_PREFIX=/usr \
	LIB=/usr/lib \
	QMAKE_CC="$CC" QMAKE_CXX="$CXX" \
	QMAKE_LINK="$CXX" QMAKE_LINK_C="$CC" \
	QMAKE_CFLAGS+="\${CFLAGS}" \
	QMAKE_CXXFLAGS+="\${CXXFLAGS}" \
	QMAKE_LFLAGS+="\${LDFLAGS}" \
	CONFIG+=no_qt_rpath
_EOF
fi
chmod 755 ${DULGE_WRAPPERDIR}/qmake
cp -p ${DULGE_WRAPPERDIR}/qmake{,-qt6}
cp -p ${DULGE_WRAPPERDIR}/qmake{,6}
