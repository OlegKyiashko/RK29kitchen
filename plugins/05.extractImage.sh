#!/bin/bash
#set -vx

MenuAdd "Extract image files" "extractMain"

initrd='initrd.img'
ramdisk='ramdisk'
system='system'
zimage='zImage'

extractStripFilesKRNL(){
	FS=$(stat -c%s "$1")
	FS=$((${FS}-12))
	dd if=$1 bs=1024K |dd bs=1 skip=8 count=${FS}|dd of=$2 bs=1024K
}

extractExtractFiles(){
	mkdir -p $ramdisk
	zcat $initrd | ( cd $ramdisk; cpio -idm )
	sudo find $ramdisk -xtype f -print0|xargs -0 ls -ln --time-style="+%F %T" |sed -e "s/ ${ramdisk}/ /">_ramdisk.lst
	sudo find $ramdisk -xtype f -print0|xargs -0 ls -ln --time-style="+" |sed -e "s/ ${ramdisk}/ /">_ramdisk.lst2

	mkdir -p $system
	sudo mount system.img $system
	sudo find $system -xtype f -print0|xargs -0 ls -ln --time-style="+%F %T"|sed -e's/ ${system}/ \/system/' >_system.lst
	sudo find $system -xtype f -print0|xargs -0 ls -ln --time-style="+"|sed -e's/ ${system}/ \/system/' >_system.lst2
#	sudo tar zcf system.tar.gz $system
	sudo umount system

	strings ${zimage} |grep "Linux version" >_kernel.version
}

extractImage(){
	pushd Image

	extractStripFilesKRNL "boot.img" "${initrd}"
	extractStripFilesKRNL "kernel.img" "${zimage}"

	extractExtractFiles

	echo "bootsize = 0x6a4000" > bootimg.cfg
	echo "pagesize = 0x4000" >> bootimg.cfg
	echo "kerneladdr = 0x60408000" >> bootimg.cfg
	echo "ramdiskaddr = 0x62000000" >> bootimg.cfg
	echo "secondaddr = 0x60f00000" >> bootimg.cfg
	echo "tagsaddr = 0x60088000" >> bootimg.cfg
	echo "name = " >> bootimg.cfg
	echo "cmdline = " >> bootimg.cfg

	popd

	WORKTYPE=2
	WORKMODE="In progress"
}

extractImgFileSelect(){
	while [ true ]
	do
		IMGFILE=""
		dialogBT
		dialog --colors --backtitle "${DIALOGBT}" --title "Choose img file" --fselect "${WORKDIR}" 20 70 2>$tempfile
		case $? in
			0)
				f=`cat $tempfile`
				if [ -f $f ]
				then
					IMGFILE=$f
					return
				fi
				;;
		esac
		dialogYN "img file not selected. Exit?"
		case $? in
			0)
				return
				;;
			*)
				continue
				;;
		esac
	done
}

extractImgFile(){

	${BINDIR}/img_unpack ${IMGFILE} ${IMGFILE}.tmp

	${BINDIR}/afptool -unpack ${IMGFILE}.tmp .

	rm ${IMGFILE}.tmp

	pushd Image

	${BINDIR}/abootimg -i boot.img > _boot.info
	${BINDIR}/abootimg -x boot.img

	extractExtractFiles

	popd

	WORKTYPE=2
	WORKMODE="In progress"
}

extractMain(){
        case ${WORKMODE} in
                "Image")
                        extractImage
                        workdirTest
                        ;;
                "*img file")
                        extractImgFileSelect
                        extractImgFile
                        workdirTest
                        ;;
                "In progress")
                        dialogMSG "Files extracted some tme ago :)"
                        ;;
                *)
                        dialogMSG "Mode unsupported now :("
                        ;;
        esac
}
