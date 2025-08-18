# Cross build profile for ARMv7 GNU EABI Hard Float.

DULGE_TARGET_MACHINE="armv7l"
DULGE_TARGET_QEMU_MACHINE="arm"
DULGE_CROSS_TRIPLET="armv7l-linux-gnueabihf"
DULGE_CROSS_CFLAGS="-march=armv7-a -mfpu=vfpv3 -mfloat-abi=hard"
DULGE_CROSS_CXXFLAGS="$DULGE_CROSS_CFLAGS"
DULGE_CROSS_FFLAGS="$DULGE_CROSS_CFLAGS"
DULGE_CROSS_RUSTFLAGS="--sysroot=${DULGE_CROSS_BASE}/usr"
DULGE_CROSS_RUST_TARGET="armv7-unknown-linux-gnueabihf"
DULGE_CROSS_ZIG_TARGET="arm-linux-gnueabihf"
DULGE_CROSS_ZIG_CPU="generic+v7a+vfp3"
