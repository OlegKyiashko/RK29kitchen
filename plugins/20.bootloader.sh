#!/bin/bash
#set -vx

MenuAdd "Change bootloader" "bootloader_BL"

bootloader_ParseBL(){
	pushd "$WORKDIR" 2>/dev/null
	BOOTLOADER=`grep bootloader package-file |cut -f2|tr -d "\n\r"`
	popd 2>/dev/null
}

bootloader_ListBL(){
	pushd "${BASEDIR}/plugins/bootloader"
	n=0

	if [ ! -f "${BOOTLOADER}" ]
	then
		cp "${WORKDIR}/${BOOTLOADER}" .
	fi

	DirToArray "*bin"
	BL=""
	for (( i=0; i<${#FILEARRAY[@]}; i++ ))
	do
		BL="$BL \"${FILEARRAY[i]}\" \"\""
	done
	BL[$n]="\"Exit\" \"\""
	popd
}

bootloader_SelectBL(){
	pushd "${BASEDIR}/plugins/bootloader"
	FilesMenuDlg "*bin" "Change bootloader" "Current bootloader: $BOOTLOADER\nChoose bootloader:"
	case $? in
		0)
			bl=`cat $tempfile`
			if [ "$bl" == "${BOOTLOADER}" ]
			then
				return
			fi
			if [ ! -f "${WORKDIR}/${bl}" ]
			then
				cp "${BASEDIR}/plugins/bootloader/$bl" "${WORKDIR}"
			fi
			pushd "$WORKDIR"
			BackupFile package-file
			cat ${COMMONBACKUPFILE}| sed -e "s/${BOOTLOADER}/${bl}/" > package-file
			popd
			;;
	esac
	popd
}

bootloader_BL(){
	cd "${WORKDIR}"
	bootloader_ParseBL
	bootloader_ListBL
	bootloader_SelectBL
}

