# Cross build profile for ARM GNU EABI5 Soft Float.

DULGE_TARGET_MACHINE="armv5tel"
DULGE_TARGET_QEMU_MACHINE="arm"
DULGE_CROSS_TRIPLET="arm-linux-gnueabi"
DULGE_CROSS_CFLAGS="-march=armv5te -msoft-float -mfloat-abi=soft"
DULGE_CROSS_CXXFLAGS="$DULGE_CROSS_CFLAGS"
DULGE_CROSS_FFLAGS="$DULGE_CROSS_CFLAGS"
DULGE_CROSS_RUSTFLAGS="--sysroot=${DULGE_CROSS_BASE}/usr"
DULGE_CROSS_RUST_TARGET="arm-unknown-linux-gnueabi"
DULGE_CROSS_ZIG_TARGET="arm-linux-gnueabi"
DULGE_CROSS_ZIG_CPU="generic+v5te+soft_float"
