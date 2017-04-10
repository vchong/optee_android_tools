#! /bin/bash

die() {
   echo "Error: $@"
   exit 1
}

if [ -z "$ANDROID_BUILD_TOP" ]; then
   echo "Error: Before running this script, setup for Android build"
   echo ""
   echo "  $ source build/envsetup.sh"
   echo "  $ lunch <target>"
fi

echo "ANDROID_PRODUCT_OUT=$ANDROID_PRODUCT_OUT"
dest="${ANDROID_PRODUCT_OUT}/kernel_obj"

cross=optee/gcc-linaro-4.9-2015.05-x86_64_aarch64-linux-gnu/bin
#if [ ! -d "$cross" ]; then
if false; then
   echo "Please run ./optee/get_toolchain.sh first"
   exit 1
fi

cross=$(realpath "$cross")
cross="$cross/aarch64-linux-gnu-"
cross="aarch64-linux-android-"

kerndir=device/linaro/hikey-kernel

CPU_CORES=$(nproc)

#flags="CROSS_COMPILE=${cross} ARCH=arm64 -j${CPU_CORES} O=${dest}"
flags="CROSS_COMPILE=${cross} ARCH=arm64 -j${CPU_CORES}"

if [ x"$1" == x"clean" ]; then
	make -C $kerndir ARCH=arm64 distclean
	exit 0
fi

#Below 2 commands do NOT work when run directly on cmd prompt! :(
make -C $kerndir ${flags} hikey_defconfig || die "Unable to configure kernel"
make -C $kerndir ${flags} || die "Unable to build kernel"
echo "cp $kerndir/arch/arm64/boot/dts/hisilicon/hi6220-hikey.dtb $kerndir/hi6220-hikey.dtb-4.9"
cp $kerndir/arch/arm64/boot/dts/hisilicon/hi6220-hikey.dtb $kerndir/hi6220-hikey.dtb-4.9
echo "cp $kerndir/arch/arm64/boot/Image-dtb $kerndir/Image-dtb-4.9"
cp $kerndir/arch/arm64/boot/Image-dtb $kerndir/Image-dtb-4.9

# if 'make bootimage' is run before a complete build is successful then we
# might be missing other files required to make the bootimage?
# http://source.android.com/source/devices.html#running-android-hikey
# Building the kernel
#make bootimage -j${CPU_CORES}
# this will create boot.img in ${ANDROID_PRODUCT_OUT}
# i.e. optee_android_manifest/out/target/product/hikey
# neither
#make bootimage -j${CPU_CORES} TARGET_BOOTIMAGE_USE_FAT=true
# nor
#TARGET_BOOTIMAGE_USE_FAT=true make bootimage -j${CPU_CORES}
# create boot_fat.uefi.img
# have to rerun 'make all' to create it
