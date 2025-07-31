if [ -z "$hostmakedepends" -o "${hostmakedepends##*gcc-go-tools*}" ]; then
	# gc compiler
	if [ -z "$archs" ]; then
		archs="i686* x86_64*"
	fi
	hostmakedepends+=" go"
	nopie=yes
else
	# gccgo compiler
	if [ -z "$archs" ]; then
		# we have support for these in our gcc
		archs="i686* x86_64*"
	fi
	if [ "$CROSS_BUILD" ]; then
		# target compiler to use; otherwise it'll just call gccgo
		export GCCGO="${DULGE_CROSS_TRIPLET}-gccgo"
	fi
fi

case "$DULGE_TARGET_MACHINE" in
	i686*) export GOARCH=386;;
	x86_64*) export GOARCH=amd64;;

esac

export GOPATH="${wrksrc}/_build-${pkgname}-dulge"
GOSRCPATH="${GOPATH}/src/${go_import_path}"
export CGO_CFLAGS="$CFLAGS"
export CGO_CPPFLAGS="$CPPFLAGS"
export CGO_CXXFLAGS="$CXXFLAGS"
export CGO_LDFLAGS="$LDFLAGS"
export CGO_ENABLED="${CGO_ENABLED:-1}"
export GO111MODULE=auto
export GOTOOLCHAIN="${GOTOOLCHAIN:-local}"
export GOPROXY="https://proxy.golang.org,direct"
export GOSUMDB="sum.golang.org"

case "$DULGE_TARGET_MACHINE" in
	*-musl) export GOCACHE="${DULGE_HOSTDIR}/gocache-muslc" ;;
	*)	export GOCACHE="${DULGE_HOSTDIR}/gocache-glibc" ;;
esac

case "$DULGE_TARGET_MACHINE" in
	# https://go.dev/cl/421935
	i686*) export CGO_CFLAGS="$CGO_CFLAGS -fno-stack-protector" ;;
esac
