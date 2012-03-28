#!/bin/sh
#set -vx

BASE_DIR=`dirname $0`
WORK_DIR=${2:-.}

$BASE_DIR/img_unpack $1 $1.tmp

$BASE_DIR/afptool -unpack $1.tmp $WORK_DIR

rm $1.tmp

cd $WORK_DIR

cd Image

$BASE_DIR/abootimg -i boot.img > _boot.info

$BASE_DIR/abootimg -x boot.img

initrd='initrd.img'
ramdisk='ramdisk'

if [ ! -f $initrd ]; then
    echo "$initrd does not exist."
    exit 1
fi

if [ -d $ramdisk ]; then
    echo "$ramdisk already exists."
    exit 1
fi

mkdir -p $ramdisk

zcat $initrd | ( cd $ramdisk; cpio -idm )

sudo find $ramdisk -xtype f -print0|xargs -0 ls -ln --time-style="+%F %T" |sed -e "s/ ${ramdisk}/ /">_ramdisk.lst
sudo find $ramdisk -xtype f -print0|xargs -0 ls -ln --time-style="+" |sed -e "s/ ${ramdisk}/ /">_ramdisk.lst2

mkdir system
sudo mount system.img system
sudo find system -xtype f -print0|xargs -0 ls -ln --time-style="+%F %T"|sed -e's/ system/ \/system/' >_system.lst
sudo find system -xtype f -print0|xargs -0 ls -ln --time-style="+"|sed -e's/ system/ \/system/' >_system.lst2
sudo umount system

strings zImage |grep "Linux version" >_kernel.version

