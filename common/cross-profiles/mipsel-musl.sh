# Cross build profile for MIPS32 LE soft float.

DULGE_TARGET_MACHINE="mipsel-musl"
DULGE_TARGET_QEMU_MACHINE="mipsel"
DULGE_CROSS_TRIPLET="mipsel-linux-musl"
DULGE_CROSS_CFLAGS="-mtune=mips32r2 -mabi=32 -msoft-float"
DULGE_CROSS_CXXFLAGS="$DULGE_CROSS_CFLAGS"
DULGE_CROSS_FFLAGS="$DULGE_CROSS_CFLAGS"
DULGE_CROSS_RUSTFLAGS="--sysroot=${DULGE_CROSS_BASE}/usr"
DULGE_CROSS_RUST_TARGET="mipsel-unknown-linux-musl"
DULGE_CROSS_ZIG_TARGET="mipsel-linux-musl"
DULGE_CROSS_ZIG_CPU="generic+soft_float"
