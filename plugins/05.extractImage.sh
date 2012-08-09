#!/bin/bash
#set -vx

MenuAdd "Extract image files" "extractImage_Main"

initrd='initrd.img'
ramdisk='ramdisk'
system='system'
zimage='zImage'

extractImage_ExtractFiles(){
	pushd Image >/dev/null

	mkdir -p $ramdisk
	zcat $initrd | ( cd $ramdisk; cpio -idm )
	${SUDO} find $ramdisk -xtype f -print0|xargs -0 ls -ln --time-style="+%F %T" |sed -e "s/ ${ramdisk}/ /">_ramdisk.lst
	${SUDO} find $ramdisk -xtype f -print0|xargs -0 ls -ln --time-style="+" |sed -e "s/ ${ramdisk}/ /">_ramdisk.lst2
	${SUDO} find $ramdisk -xtype f -print0|xargs -0 ls -l|awk '{print $5 "\t" $9}' |sed -e "s/ ${ramdisk}/ /">_ramdisk.lst3

	if [ -f recovery-$initrd ]
	then
		mkdir -p recovery-$ramdisk
		zcat "recovery-$initrd" | ( cd "recovery-$ramdisk"; cpio -idm )
		${SUDO} find recovery-$ramdisk -xtype f -print0|xargs -0 ls -ln --time-style="+%F %T" |sed -e "s/ recovery-${ramdisk}/ /">_recovery-ramdisk.lst
		${SUDO} find recovery-$ramdisk -xtype f -print0|xargs -0 ls -ln --time-style="+" |sed -e "s/  recovery-${ramdisk}/ /">_recovery-ramdisk.lst2
		${SUDO} find recovery-$ramdisk -xtype f -print0|xargs -0 ls -l|awk '{print $5 "\t" $9}' |sed -e "s/  recovery-${ramdisk}/ /">_recovery-ramdisk.lst3
	fi

#	SystemMount
#	${SUDO} find $system -xtype f -print0|xargs -0 ls -ln --time-style="+%F %T"|sed -e's/ ${system}/ \/system/' >_system.lst
#	${SUDO} find $system -xtype f -print0|xargs -0 ls -ln --time-style="+"|sed -e's/ ${system}/ \/system/' >_system.lst2
#	${SUDO} find $system -xtype f -print0|xargs -0 ls -l|awk '{print $5 "\t" $9}'|sed -e's/ ${system}/ \/system/' >_system.lst3
#	SystemUmount

	strings ${zimage} |grep "Linux version" >_kernel.version
	if [ -f recovery-$zimage ]
	then
		strings recovery-${zimage} |grep "Linux version" >_recovery-kernel.version
	fi
	popd >/dev/null
}

extractImage_ExtractBootImg(){
	pushd Image >/dev/null
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
#			popd >/dev/null
#			exit 1
	esac
	popd >/dev/null
}

extractImage_ExtractKernelImg(){
	if [ ! -f Image/kernel.img ]
	then
		return
	fi

	pushd Image >/dev/null
	FileSignature kernel.img
	case $COMMONFILESIGNATURE in
		"KRNL")
			mkkrnlimg -r kernel.img "${zimage}"
			;;
		*)
			dialogOK "Unknown kernel.img type :("
#			popd >/dev/null
#			exit 1
	esac
	popd >/dev/null
}

extractImage_ExtractRecoveryImg(){
	if [ ! -f Image/recovery.img ]
	then
		return
	fi

	pushd Image >/dev/null
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
#			popd >/dev/null
#			exit 1
	esac
	popd >/dev/null
}

extractImage_ExtractProcess(){
	pushd "$WORKDIR" >/dev/null
	BackupFile package-file
	cat ${COMMONBACKUPFILE}| sed -e "s/#kernel/kernel/" > package-file
	popd >/dev/null

	extractImage_ExtractBootImg
	extractImage_ExtractKernelImg
	extractImage_ExtractRecoveryImg
	extractImage_ExtractFiles
	workdir_Test
}

extractImage_ExtractImage(){
	pushd "$WORKDIR" >/dev/null
	cp "${PLUGINS}/extractImage/bootimg.cfg" Image/
	cp "${PLUGINS}/extractImage/recovery.cfg" Image/

	cp "${PLUGINS}/extractImage/package-file" .
	cp "${PLUGINS}/extractImage/recover-script" .
	cp "${PLUGINS}/extractImage/update-script" .

	mv parameter1G parameter 2>/dev/null

	BOOTLOADER=`grep bootloader package-file |cut -f2|tr -d "\n\r"`
	bl=`ls -1 RK29*bin`
	if [ "$BOOTLOADER" != "$bl" ]
	then
		BackupFile package-file
		cat ${COMMONBACKUPFILE}| sed -e "s/${BOOTLOADER}/${bl}/" > package-file
	fi
	popd >/dev/null
	extractImage_ExtractProcess
}

extractImage_ExtractImgFile(){
	IMGFILE="$1"
	img_unpack "${IMGFILE}" "update.img.tmp"
	afptool -unpack "update.img.tmp" .
#	rm "update.img.tmp"
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
