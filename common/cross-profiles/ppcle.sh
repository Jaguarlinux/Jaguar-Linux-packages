# Cross build profile for little endian PowerPC.

DULGE_TARGET_MACHINE="ppcle"
DULGE_TARGET_QEMU_MACHINE="ppcle"
DULGE_CROSS_TRIPLET="powerpcle-linux-gnu"
DULGE_CROSS_CFLAGS="-mcpu=power8 -mtune=power9"
DULGE_CROSS_CXXFLAGS="$DULGE_CROSS_CFLAGS"
DULGE_CROSS_FFLAGS="$DULGE_CROSS_CFLAGS"
DULGE_CROSS_RUSTFLAGS="--sysroot=${DULGE_CROSS_BASE}/usr"
DULGE_CROSS_RUST_TARGET="powerpcle-unknown-linux-gnu"
DULGE_CROSS_ZIG_TARGET="powerpcle-linux-gnu"
DULGE_CROSS_ZIG_CPU="pwr8"
