# Cross build profile for MIPS32 LE hardfloat.

DULGE_TARGET_MACHINE="mipselhf-musl"
DULGE_TARGET_QEMU_MACHINE="mipsel"
DULGE_CROSS_TRIPLET="mipsel-linux-muslhf"
DULGE_CROSS_CFLAGS="-mtune=mips32r2 -mabi=32 -mhard-float"
DULGE_CROSS_CXXFLAGS="$DULGE_CROSS_CFLAGS"
DULGE_CROSS_FFLAGS="$DULGE_CROSS_CFLAGS"
DULGE_CROSS_RUSTFLAGS="--sysroot=${DULGE_CROSS_BASE}/usr"
DULGE_CROSS_RUST_TARGET="mipsel-unknown-linux-musl"
DULGE_CROSS_ZIG_TARGET="mipsel-linux-musl"
DULGE_CROSS_ZIG_CPU="generic"
