#!/bin/bash
# Script to build flashable ZZKernel zip for a5ultexx

BUILD_START=$(date +"%s")

# Colours
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

# Kernel details
KERNEL_NAME="ZZKernel"
VERSION="X1-Phoenix"
DATE=$(date +"%d-%m-%Y")
DEVICE="a5ultexx"
FINAL_ZIP=$KERNEL_NAME-$VERSION-$DATE-$DEVICE.zip
defconfig=msm8916_sec_defconfig
VARIANT_DEFCONFIG=msm8916_sec_a5u_eur_defconfig
SELINUX_DEFCONFIG=selinux_defconfig

# Toolchain repo
TC_REPO="https://github.com/Soft-Bullet/arm-eabi-7.2"

# Dirs
KERNEL_DIR=$(pwd)
ANYKERNEL_DIR=$KERNEL_DIR/AnyKernel2
KERNEL_IMG=$KERNEL_DIR/out/arch/arm/boot/zImage
DT_IMAGE=$KERNEL_DIR/out/arch/arm/boot/dt.img
UPLOAD_DIR=$KERNEL_DIR/OUTPUT/$DEVICE
DTBTOOL=$KERNEL_DIR/dtbTool
TOOLCHAIN=/home/BinayDEV/kernel/arm-eabi-7.2

# Export
export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE=$TOOLCHAIN/bin/arm-eabi-
export KBUILD_BUILD_USER="ThePhoenix"
export KBUILD_BUILD_USER="Soft-Bullet"

## Functions ##

# Make kernel
function make_kernel() {
  if [ ! -d "$TOOLCHAIN" ]; then git clone -b kek $TC_REPO $TOOLCHAIN; fi
  mkdir out
  echo -e "$cyan***********************************************"
  echo -e "          Initializing defconfig          "
  echo -e "***********************************************$nocol"
  make msm8916_sec_defconfig VARIANT_DEFCONFIG=msm8916_sec_a5u_eur_defconfig SELINUX_DEFCONFIG=selinux_defconfig O=out
  echo -e "$cyan***********************************************"
  echo -e "             Building kernel          "
  echo -e "***********************************************$nocol"
  make -j`nproc --all` O=out
  if ! [ -a $KERNEL_IMG ];
  then
    echo -e "$red Kernel Compilation failed! Fix the errors! $nocol"
  fi
}

# Make DT.IMG
function make_dt(){
$DTBTOOL -2 -o ./out/arch/arm/boot/dt.img -s 2048 -p ./out/scripts/dtc/ ./out/arch/arm/boot/dts/ -v
}

# Making zip
function make_zip() {
mkdir -p tmp_mod
cp $KERNEL_IMG $ANYKERNEL_DIR
cp $DT_IMAGE $ANYKERNEL_DIR
mkdir -p $UPLOAD_DIR
cd $ANYKERNEL_DIR
zip -r9 UPDATE-AnyKernel2.zip * -x README UPDATE-AnyKernel2.zip
mv $ANYKERNEL_DIR/UPDATE-AnyKernel2.zip $UPLOAD_DIR/$FINAL_ZIP
rm -rf $KERNEL_DIR/tmp_mod
cd $UPLOAD_DIR
}

# Options
function options() {
echo -e "$cyan***********************************************"
  echo "               Compiling ZZKernel                "
  echo -e "***********************************************$nocol"
  echo -e " "
  echo -e " Select if you want zip or just kernel : "
  echo -e " 1.Get flashable zip"
  echo -e " 2.Get kernel only"
  echo -n " Your choice : ? "
  read ziporkernel

echo -e "$cyan***********************************************"
     echo -e "          	Clean          "
     echo -e "***********************************************$nocol"
     make clean
     make mrproper
     rm -rf tmp_mod
     make_kernel
     make_dt

if [ "$ziporkernel" = "1" ]; then
     echo -e "$cyan***********************************************"
     echo -e "     Making flashable zip        "
     echo -e "***********************************************$nocol"
     make_zip
else
     echo -e "$cyan***********************************************"
     echo -e "     Building Kernel only        "
     echo -e "***********************************************$nocol"
fi
}

# Clean Up
function cleanup(){
rm -rf $KERNEL_IMG
rm -rf $DT_IMAGE
}

options
cleanup
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
