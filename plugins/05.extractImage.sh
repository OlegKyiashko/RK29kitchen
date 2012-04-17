#!/bin/bash
#set -vx

MenuAdd "Extract image files" "extractMain"
MenuAdd "Mount /system to Image/system" "extractMount"
MenuAdd "Umount /system from Image/system" "extractUmount"

initrd='initrd.img'
ramdisk='ramdisk'
system='system'
zimage='zImage'

extractMount(){
	sudo mount "${WORKDIR}/Image/system.img" "${WORKDIR}/Image/$system"
	if [ $? -eq 0 ]
	then
		dialogINF Mount OK
	else
		dialogINF Mount error
	fi		
}

extractUmount(){
	sudo umount -f "${WORKDIR}/Image/$system"
	if [ $? -eq 0 ]
	then
		dialogINF Umount OK
	else
		dialogINF Umount error
	fi		
}

extractStripFilesKRNL(){
	sz=`stat -c%s "$1"`
	sz=$[${sz}-12]
	dd if="$1" bs=1024K |dd bs=1 skip=8 count=${sz}|dd of=$2 bs=1024K
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
	#sudo tar zcf system.tar.gz $system
	#sudo umount system

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
				if [ -f "$f" ]
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

	img_unpack "${IMGFILE}" "${IMGFILE}.tmp"

	afptool -unpack "${IMGFILE}.tmp" .

	rm "${IMGFILE}.tmp"

	pushd Image

	abootimg -i boot.img > _boot.info
	abootimg -x boot.img

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
			dialogOK "Files extracted some time ago :)"
			;;
		*)
			dialogOK "Mode unsupported now :("
			;;
	esac
}
