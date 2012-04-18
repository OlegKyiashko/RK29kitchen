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
	pushd Image

	mkdir -p $ramdisk
	zcat $initrd | ( cd $ramdisk; cpio -idm )
	sudo find $ramdisk -xtype f -print0|xargs -0 ls -ln --time-style="+%F %T" |sed -e "s/ ${ramdisk}/ /">_ramdisk.lst
	sudo find $ramdisk -xtype f -print0|xargs -0 ls -ln --time-style="+" |sed -e "s/ ${ramdisk}/ /">_ramdisk.lst2

	if [ -f recovery-$initrd ]
	then
		mkdir -p recovery-$ramdisk
		zcat recovery-$initrd | ( cd recovery-$ramdisk; cpio -idm )
		sudo find recovery-$ramdisk -xtype f -print0|xargs -0 ls -ln --time-style="+%F %T" |sed -e "s/ ${ramdisk}/ /">_recovery-ramdisk.lst
		sudo find recovery-$ramdisk -xtype f -print0|xargs -0 ls -ln --time-style="+" |sed -e "s/ ${ramdisk}/ /">_recovery-ramdisk.lst2
	fi

	mkdir -p $system
	sudo mount system.img $system
	sudo find $system -xtype f -print0|xargs -0 ls -ln --time-style="+%F %T"|sed -e's/ ${system}/ \/system/' >_system.lst
	sudo find $system -xtype f -print0|xargs -0 ls -ln --time-style="+"|sed -e's/ ${system}/ \/system/' >_system.lst2
	#sudo tar zcf system.tar.gz $system
	#sudo umount system

	strings ${zimage} |grep "Linux version" >_kernel.version
	if [ -f recovery-$zimage ]
	then
		strings recovery-${zimage} |grep "Linux version" >_recovery-kernel.version
	fi
	popd
}

extractExtractBootImg(){
	pushd Image
	commonFileSignature boot.img
	case $COMMONFILESIGNATURE in
		"ANDR")
			abootimg -i boot.img > _boot.info
			abootimg -x boot.img
			;;
		"KRNL")
			mkkrnlimg -r "boot.img" "${initrd}"
			;;
		*)
			dialogOK "Unknown boot.img type :("
			popd
			exit 1
	esac
	popd
}

extractExtractKernelImg(){
	if [ ! -f Image/kernel.img ]
	then
		return
	fi

	pushd Image
	commonFileSignature kernel.img
	case $COMMONFILESIGNATURE in
		"KRNL")
			mkkrnlimg -r kernel.img "${zimage}"
			;;
		*)
			dialogOK "Unknown kernel.img type :("
			popd
			exit 1
	esac
	popd
}

extractExtractRecoveryImg(){
	if [ ! -f Image/recovery.img ]
	then
		return
	fi

	pushd Image
	commonFileSignature recovery.img
	case $COMMONFILESIGNATURE in
		"KRNL")
			mkkrnlimg -r recovery.img recovery-$initrd
			;;
		"ANDR")
			abootimg -i recovery.img > _recovery.info
			abootimg -x recovery.img recovery.cfg recovery-${zimage} recovery-${initrd}
			;;
		*)
			dialogOK "Unknown recovery.img type :("
			popd
			exit 1
	esac
	popd
}


extractExtractImage(){
	cp "${PLUGINS}"/extractImage/bootimg.cfg Image/

	cp "${PLUGINS}"/extractImage/package-file .
	cp "${PLUGINS}"/extractImage/recover-script .
	cp "${PLUGINS}"/extractImage/update-script .

	mv parameter1G parameter 2>/dev/null

	BOOTLOADER=`grep bootloader package-file |cut -f2|tr -d "\n\r"`
	bl=`ls -1 RK29*bin`
	if [ "$BOOTLOADER" != "$bl" ]
	then
		commonBackupFile package-file
		cat ${COMMONBACKUPFILE}| sed -e "s/${BOOTLOADER}/${bl}/" > package-file
	fi
}

extractExtractImg(){
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
					img_unpack "${IMGFILE}" "${IMGFILE}.tmp"
					afptool -unpack "${IMGFILE}.tmp" .
					rm "${IMGFILE}.tmp"
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

extractExtractProcess(){
	extractExtractBootImg
	extractExtractKernelImg
	extractExtractRecoveryImg
	extractExtractFiles
	workdirTest
}

extractMain(){
	cd "$WORKDIR"
	workdirTest
	case ${WORKMODE} in
		"Image")
			extractExtractImage
			extractExtractProcess
			;;
		"*img file")
			extractExtractImg
			extractExtractProcess
			;;
		"In progress")
			dialogOK "Files extracted some time ago :)"
			;;
		*)
			dialogOK "Mode unsupported now :("
			;;
	esac
}
