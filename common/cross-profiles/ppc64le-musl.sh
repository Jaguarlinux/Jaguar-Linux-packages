# Cross build profile for ppc64 little-endian musl.

DULGE_TARGET_MACHINE="ppc64le-musl"
DULGE_TARGET_QEMU_MACHINE="ppc64le"
DULGE_CROSS_TRIPLET="powerpc64le-linux-musl"
DULGE_CROSS_CFLAGS="-mtune=power9"
DULGE_CROSS_CXXFLAGS="$DULGE_CROSS_CFLAGS"
DULGE_CROSS_FFLAGS="$DULGE_CROSS_CFLAGS"
DULGE_CROSS_RUSTFLAGS="--sysroot=${DULGE_CROSS_BASE}/usr"
DULGE_CROSS_RUST_TARGET="powerpc64le-unknown-linux-musl"
DULGE_CROSS_ZIG_TARGET="powerpc64le-linux-musl"
DULGE_CROSS_ZIG_CPU="baseline"
