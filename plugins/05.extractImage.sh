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

	mkkrnlimg -r "boot.img" "${initrd}"
	mkkrnlimg -r "kernel.img" "${zimage}"

	extractExtractFiles

	cp "${PLUGINS}"/extractImage/bootimg.cfg .

	popd

	cp "${PLUGINS}"/extractImage/package-file .
	cp "${PLUGINS}"/extractImage/recover-script .
	cp "${PLUGINS}"/extractImage/update-script .
	
	mv parameter1G parameter 2>/dev/null

	BOOTLOADER=`grep bootloader package-file |cut -f2|tr -d "\n\r"`
	bl=`ls -1 RK29*bin`
	if [ "$BOOTLOADER" != "$bl" ]
	then
		commonBackupFile package-file
		cat COMMONBACKUPFILE| sed -e "s/${BOOTLOADER}/${bl}/" > package-file
	fi

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
