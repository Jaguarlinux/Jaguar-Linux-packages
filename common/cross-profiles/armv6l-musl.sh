# Cross build profile for ARM EABI5 Hard Float and Musl libc.

DULGE_TARGET_MACHINE="armv6l-musl"
DULGE_TARGET_QEMU_MACHINE="arm"
DULGE_CROSS_TRIPLET="arm-linux-musleabihf"
DULGE_CROSS_CFLAGS="-march=armv6 -mfpu=vfp -mfloat-abi=hard"
DULGE_CROSS_CXXFLAGS="$DULGE_CROSS_CFLAGS"
DULGE_CROSS_FFLAGS="$DULGE_CROSS_CFLAGS"
DULGE_CROSS_RUSTFLAGS="--sysroot=${DULGE_CROSS_BASE}/usr"
DULGE_CROSS_RUST_TARGET="arm-unknown-linux-musleabihf"
DULGE_CROSS_ZIG_TARGET="arm-linux-musleabihf"
DULGE_CROSS_ZIG_CPU="generic+v6"
