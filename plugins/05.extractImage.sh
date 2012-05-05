#!/bin/bash
#set -vx

MenuAdd "Extract image files" "extractImage_Main"

initrd='initrd.img'
ramdisk='ramdisk'
system='system'
zimage='zImage'

extractImage_ExtractFiles(){
	pushd Image

	mkdir -p $ramdisk
	zcat $initrd | ( cd $ramdisk; cpio -idm )
	sudo find $ramdisk -xtype f -print0|xargs -0 ls -ln --time-style="+%F %T" |sed -e "s/ ${ramdisk}/ /">_ramdisk.lst
	sudo find $ramdisk -xtype f -print0|xargs -0 ls -ln --time-style="+" |sed -e "s/ ${ramdisk}/ /">_ramdisk.lst2
	sudo find $ramdisk -xtype f -print0|xargs -0 ls -l|awk '{print $5 "\t" $9}' |sed -e "s/ ${ramdisk}/ /">_ramdisk.lst3

	if [ -f recovery-$initrd ]
	then
		mkdir -p recovery-$ramdisk
		zcat recovery-$initrd | ( cd recovery-$ramdisk; cpio -idm )
		sudo find recovery-$ramdisk -xtype f -print0|xargs -0 ls -ln --time-style="+%F %T" |sed -e "s/ recovery-${ramdisk}/ /">_recovery-ramdisk.lst
		sudo find recovery-$ramdisk -xtype f -print0|xargs -0 ls -ln --time-style="+" |sed -e "s/  recovery-${ramdisk}/ /">_recovery-ramdisk.lst2
		sudo find recovery-$ramdisk -xtype f -print0|xargs -0 ls -l|awk '{print $5 "\t" $9}' |sed -e "s/  recovery-${ramdisk}/ /">_recovery-ramdisk.lst3
	fi

	SystemMount
	sudo find $system -xtype f -print0|xargs -0 ls -ln --time-style="+%F %T"|sed -e's/ ${system}/ \/system/' >_system.lst
	sudo find $system -xtype f -print0|xargs -0 ls -ln --time-style="+"|sed -e's/ ${system}/ \/system/' >_system.lst2
	sudo find $system -xtype f -print0|xargs -0 ls -l|awk '{print $5 "\t" $9}'|sed -e's/ ${system}/ \/system/' >_system.lst3

	strings ${zimage} |grep "Linux version" >_kernel.version
	if [ -f recovery-$zimage ]
	then
		strings recovery-${zimage} |grep "Linux version" >_recovery-kernel.version
	fi
	popd
}

extractImage_ExtractBootImg(){
	pushd Image
	FileSignature boot.img
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

extractImage_ExtractKernelImg(){
	if [ ! -f Image/kernel.img ]
	then
		return
	fi

	pushd Image
	FileSignature kernel.img
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

extractImage_ExtractRecoveryImg(){
	if [ ! -f Image/recovery.img ]
	then
		return
	fi

	pushd Image
	FileSignature recovery.img
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

extractImage_ExtractProcess(){
	extractImage_ExtractBootImg
	extractImage_ExtractKernelImg
	extractImage_ExtractRecoveryImg
	extractImage_ExtractFiles
	workdir_Test
}

extractImage_ExtractImage(){
	pushd "$WORKDIR"
	cp "${PLUGINS}"/extractImage/bootimg.cfg Image/

	cp "${PLUGINS}"/extractImage/package-file .
	cp "${PLUGINS}"/extractImage/recover-script .
	cp "${PLUGINS}"/extractImage/update-script .

	mv parameter1G parameter 2>/dev/null

	BOOTLOADER=`grep bootloader package-file |cut -f2|tr -d "\n\r"`
	bl=`ls -1 RK29*bin`
	if [ "$BOOTLOADER" != "$bl" ]
	then
		BackupFile package-file
		cat ${COMMONBACKUPFILE}| sed -e "s/${BOOTLOADER}/${bl}/" > package-file
	fi
	popd
	extractImage_ExtractProcess
}

extractImage_ExtractImgFile(){
	IMGFILE="$1"
	img_unpack "${IMGFILE}" "${IMGFILE}.tmp"
	afptool -unpack "${IMGFILE}.tmp" .
	rm "${IMGFILE}.tmp"
	extractImage_ExtractProcess
}

extractImage_ExtractImg(){
	while [ true ]
	do
		IMGFILE=""
		FilesMenuDlg "*.img" "Extract image files" "Choose img file"
		case $? in
			0)
				f=`cat $tempfile`
				if [ -f "$f" ]
				then
					extractImage_ExtractImgFile "$f"
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

extractImage_Main(){
	cd "$WORKDIR"
	workdir_Test
	case ${WORKMODE} in
		"Image")
			extractImage_ExtractImage
			;;
		"*img file")
			extractImage_ExtractImg
			;;
		"In progress")
			dialogOK "Files extracted some time ago :)"
			;;
		*)
			dialogOK "Mode unsupported now :("
			;;
	esac
}
