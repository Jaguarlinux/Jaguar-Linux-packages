# Cross build profile for ARM GNU EABI5 Soft Float and Musl libc.

DULGE_TARGET_MACHINE="armv5tel-musl"
DULGE_TARGET_QEMU_MACHINE="arm"
DULGE_CROSS_TRIPLET="arm-linux-musleabi"
DULGE_CROSS_CFLAGS="-march=armv5te -msoft-float -mfloat-abi=soft"
DULGE_CROSS_CXXFLAGS="$DULGE_CROSS_CFLAGS"
DULGE_CROSS_FFLAGS="$DULGE_CROSS_CFLAGS"
DULGE_CROSS_RUSTFLAGS="--sysroot=${DULGE_CROSS_BASE}/usr"
DULGE_CROSS_RUST_TARGET="arm-unknown-linux-musleabi"
DULGE_CROSS_ZIG_TARGET="arm-linux-musleabi"
DULGE_CROSS_ZIG_CPU="generic+v5te+soft_float"
