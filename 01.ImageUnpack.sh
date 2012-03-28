#set -vx
WRK_DIR=${1:-.}
cd ${WRK_DIR}

extract(){
	FS=$(stat -c%s "$1")
	FS=$((${FS}-12))
	dd if=$1 bs=1024K |dd bs=1 skip=8 count=${FS}|dd of=$2 bs=1024K
}

initrd='initrd.img'
ramdisk='ramdisk'

extract boot.img ${initrd}
extract kernel.img zImage


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

cat > bootimg.cfg <<EOF
bootsize = 0x6a4000
pagesize = 0x4000
kerneladdr = 0x60408000
ramdiskaddr = 0x62000000
secondaddr = 0x60f00000
tagsaddr = 0x60088000
name = 
cmdline = 
EOF