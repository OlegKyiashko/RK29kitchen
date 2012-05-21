#!/bin/bash
#set -vx

MenuAdd "Make update.img image file" "makeUpdateImage_Main"

initrd='initrd.img'
ramdisk='ramdisk'
system='system'
zimage='zImage'
img='update.img'
MADEIMAGE=0

makeUpdateImage_MkInitRD(){
	pushd "${WORKDIR}/Image/" >/dev/null

	BackupFile "${initrd}"
	BackupFile boot.img

	cd $ramdisk
	find . -type f -name "*#" -print0 | xargs -0 ${SUDO} rm -f 
	find . -exec touch -d "1970-01-01 01:00" {} \;
	find . ! -name "."|sort|cpio -oa -H newc --owner=root:root|gzip -n >../${initrd}
	cd ..

	BackupFile "recovery-${initrd}"
	BackupFile recovery.img

	cd recovery-$ramdisk
	find . -type f -name "*#" -print0 | xargs -0 ${SUDO} rm -f 
	find . -exec touch -d "1970-01-01 01:00" {} \;
	find . ! -name "."|sort|cpio -oa -H newc --owner=root:root|gzip -n >../recovery-${initrd}
	cd ..

	abootimg --create boot.img -f bootimg.cfg -k $zimage -r ${initrd}
	abootimg --create recovery.img -f recovery.cfg -k $zimage -r recovery-${initrd}

	mkkrnlimg -a "${zimage}" kernel.img

	popd >/dev/null
}

makeUpdateImage_Image(){
	cd "${WORKDIR}"
	${SUDO} rm Image/system/build.prop.original

	SystemUmount

	if [ -z "${BOOTLOADER}" ]
	then
		bootloader_ParseBL
	fi
	afptool -pack . ${img}.tmp 2>>"${LOGFILE}"
	if [ ! -f "${img}.tmp" ]
	then
		dialogLOG "Make update image error"
		exit 1
	fi

	BackupFile ${img}
	img_maker $BOOTLOADER ${img}.tmp ${img}
	#rm ${img}.tmp
	#        zip update.zip update.img
	MADEIMAGE=1
}

makeUpdateImage_Process(){
	makeUpdateImage_MkInitRD
	makeUpdateImage_Image
}

makeUpdateImage_Main(){
	cd "$WORKDIR"
	case ${WORKMODE} in
		"In progress")
			makeUpdateImage_Process
			;;
		*)
			dialogOK "Mode unsupported now!"
			;;
	esac
}

