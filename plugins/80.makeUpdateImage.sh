#!/bin/bash
#set -vx

MenuAdd "Change bootloader" "makeUpdateBL"
MenuAdd "Make update.img image file" "makeUpdateMain"

initrd='initrd.img'
ramdisk='ramdisk'
system='system'
zimage='zImage'
img='update.img'

makeUpdateParseBL(){
	BOOTLOADER=`grep bootloader package-file |cut -f2|tr -d "\n\r"`
}

makeUpdateListBL(){
	pushd "${BASEDIR}/plugins/bootloader"
	n=0

	if [ ! -f "${BOOTLOADER}" ]
	then
		cp "${WORKDIR}/${BOOTLOADER}" .
	fi

	for f in *bin
	do
		BL[$n]="\"$f\" \"\""
		n=$[n+1]
	done
	BL[$n]="\"Exit\" \"\""
	popd
}

makeUpdateSelectBL(){
	echo ${BL[@]}| xargs dialog --colors --backtitle "${DIALOGBT}" --title "Change bootloader" \
	  --menu "Current bootloader: $BOOTLOADER\nChoose bootloader:" 20 70 15 2>$tempfile
	case $? in
		0)
			bl=`cat $tempfile`
			if [ "$bl" == "Exit" ] || [ "$bl" == "${BOOTLOADER}" ]
			then
				return
			fi
			if [ ! -f "${WORKDIR}/${bl}" ]
			then
				cp "${BASEDIR}/plugins/bootloader/$bl" "${WORKDIR}"
			fi
			commonBackupFile package-file
			cat ${COMMONBACKUPFILE}| sed -e "s/${BOOTLOADER}/${bl}/" > package-file
			;;
	esac
}

makeUpdateBL(){
	cd "${WORKDIR}"
	makeUpdateParseBL
	makeUpdateListBL
	makeUpdateSelectBL
}

makeUpdateMkInitRD(){
	#mkinitrd
	pushd "${WORKDIR}/Image/"

	commonBackupFile "${initrd}"
	commonBackupFile boot.img

	cd $ramdisk
	find . -exec touch -d "1970-01-01 01:00" {} \;
	find . ! -name "."|sort|cpio -oa -H newc --owner=root:root|gzip -n >../${initrd}

	commonBackupFile "recovery-${initrd}"
	commonBackupFile recovery.img

	cd ../recovery-$ramdisk
	find . -exec touch -d "1970-01-01 01:00" {} \;
	find . ! -name "."|sort|cpio -oa -H newc --owner=root:root|gzip -n >../recovery-${initrd}

	cd ..
	abootimg --create boot.img -f bootimg.cfg -k $zimage -r ${initrd}
	abootimg --create recovery.img -f recovery.cfg -k $zimage -r recovery-${initrd}

	mkkrnlimg -a "${zimage}" kernel.img

	popd
}

makeUpdateImage(){
	cd "${WORKDIR}"
	if [ -z "${BOOTLOADER}" ]
	then
		makeUpdateParseBL
	fi
	afptool -pack . ${img}.tmp 2>>"${LOGFILE}"
	if [ ! -f "${img}.tmp" ]
	then
		dialogLOG "Make update image error"
		exit 1
	fi
	commonBackupFile ${img}
	img_maker $BOOTLOADER ${img}.tmp ${img}
	rm ${img}.tmp
}

makeUpdateProcess(){
	makeUpdateMkInitRD
	makeUpdateImage
}

makeUpdateMain(){
	cd "$WORKDIR"
	case ${WORKMODE} in
		"In progress")
			makeUpdateProcess
			;;
		*)
			dialogOK "Mode unsupported now!"
			;;
	esac
}
