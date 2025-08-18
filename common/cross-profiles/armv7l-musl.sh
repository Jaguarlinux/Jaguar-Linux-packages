# Cross build profile for ARMv7 EABI Hard Float and Musl libc.

DULGE_TARGET_MACHINE="armv7l-musl"
DULGE_TARGET_QEMU_MACHINE="arm"
DULGE_CROSS_TRIPLET="armv7l-linux-musleabihf"
DULGE_CROSS_CFLAGS="-march=armv7-a -mfpu=vfpv3 -mfloat-abi=hard"
DULGE_CROSS_CXXFLAGS="$DULGE_CROSS_CFLAGS"
DULGE_CROSS_FFLAGS="$DULGE_CROSS_CFLAGS"
DULGE_CROSS_RUSTFLAGS="--sysroot=${DULGE_CROSS_BASE}/usr"
DULGE_CROSS_RUST_TARGET="armv7-unknown-linux-musleabihf"
DULGE_CROSS_ZIG_TARGET="arm-linux-musleabihf"
DULGE_CROSS_ZIG_CPU="generic+v7a+vfp3"
