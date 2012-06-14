#!/bin/bash
#set -vx

MenuAdd "System apps" "installApps_Menu"

installApps_BB(){
	SystemMount
	cd "$WORKDIR/Image"

	${SUDO} cp "${PLUGINS}/installApps/bin/busybox" system/xbin/busybox 2>>"${LOGFILE}"

	for c in `cat "${PLUGINS}/installApps/bin/busybox.lst"`
	do
		dst="system/xbin/${c}"
		if [ -f "$dst" ] || [ -L "$dst" ]
		then
			${SUDO} mv "$dst" "${dst}#"
		fi

		${SUDO} ln -s /system/xbin/busybox ${dst} 2>>"${LOGFILE}"
	done

	SystemFixPermissions
}

installApps_SU(){
	SystemMount
	cd "$WORKDIR/Image"

	${SUDO} mv system/bin/su "system/bin/su#" 2>/dev/null 
	${SUDO} mv system/xbin/su "system/xbin/su#" 2>/dev/null

	${SUDO} cp "${PLUGINS}/installApps/bin/su" system/xbin/su 2>>"${LOGFILE}"
	${SUDO} cp "${PLUGINS}/installApps/bin/Superuser.apk" system/app/ 2>>"${LOGFILE}"

	SystemFixPermissions
}

installApps_ExtractSystemLibs(){
	pushd "${WORKDIR}/Image/system/app/" >/dev/null
	DirToArray "*.apk"
	n=${#FILEARRAY[@]}
	for (( i=0; i<${n}; i++ ))
	do
		f=${FILEARRAY[$i]}
		ApkLibExtract "$f"
		if [ ! -z "${APKLIBFILES}" ]
		then
			pushd "${APKLIBDIR}" >/dev/null
			${SUDO} cp *.so "${WORKDIR}/Image/system/lib/"  2>>"${LOGFILE}"
			popd >/dev/null
		fi
	done
	popd >/dev/null
}

installApps_RemoveListApk(){
	SystemMount
	apklist=("${!1}")
	pushd "${WORKDIR}/Image/system/app/" >/dev/null
	apklistsize=${#apklist[@]}
	for (( i=0; i<${apklistsize}; i++ ))
	do
		f=${apklist[$i]}
		if [ -z "$f" ]
		then
			continue
		fi
		ApkLibExtract "$f"
		if [ ! -z "${APKLIBFILES}" ]
		then
			pushd "${APKLIBDIR}" >/dev/null
			DirToArray "*.so"
			popd >/dev/null
			s=${#FILEARRAY[@]}
			for (( j=0; j<${s}; j++ ))
			do
				so="${FILEARRAY[$j]}"
				${SUDO} rm "${WORKDIR}/Image/system//lib/$so" 2>>"${LOGFILE}"
			done
		fi
		${SUDO} rm "${WORKDIR}/Image/system/app/$f" 2>>"${LOGFILE}"
	done
	popd >/dev/null

	installApps_ExtractSystemLibs
	SystemFixPermissions
}

installApps_RemoveAllApk(){
	SystemMount

	pushd "${WORKDIR}/Image/system/app/" >/dev/null
	ls -1|grep -f "${PLUGINS}/installApps/apkblacklist.txt" > "$tempfile"
	FileToArray "$tempfile"
	popd >/dev/null

	installApps_RemoveListApk FILEARRAY[@]
}

installApps_RemoveSelectedApk(){
	SystemMount

	pushd "${WORKDIR}/Image/system/app/" >/dev/null
	ls -1|grep -f "${PLUGINS}/installApps/apkblacklist.txt" > "$tempfile"
	FileToArray "$tempfile"
	bl=("${FILEARRAY[@]}")
	ls -1|grep -v -f "${PLUGINS}/installApps/apkwhitelist.txt"|grep -v -f "${PLUGINS}/installApps/apkblacklist.txt" > "$tempfile"
	FileToArray "$tempfile"
	gl=("${FILEARRAY[@]}")
	popd  >/dev/null
	ListCheckboxDlg bl[@] gl[@] "Remove system apps" "Choose apk files:"
	if [ $? -eq 0 ]
	then
		installApps_RemoveListApk FILEARRAY[@]
	fi
}

installApps_InstallListApk(){
	SystemMount
	apklist=("${!1}")
	pushd "${PLUGINS}/installApps/apk" >/dev/null
	apklistsize=${#apklist[@]}
	for (( i=0; i<${apklistsize}; i++ ))
	do
		f=${apklist[$i]}
		${SUDO} cp $f "${WORKDIR}/Image/system/app/"  2>>"${LOGFILE}"
	done
	popd >/dev/null
	installApps_ExtractSystemLibs
	SystemFixPermissions
}

installApps_InstallAllApk(){
	pushd "${PLUGINS}/installApps/apk" >/dev/null
	DirToArray "*apk"
	installApps_InstallListApk FILEARRAY[@]
	popd >/dev/null
}

installApps_InstallSelectedApk(){
	pushd "${PLUGINS}/installApps/apk" >/dev/null
	DirToArray "*apk"
	ListCheckboxDlg FILEARRAY[@] "" "Install apps as system" "Choose apk files:"
	if [ $? -eq 0 ]
	then
		installApps_InstallListApk FILEARRAY[@]
	fi
	popd >/dev/null
}

installApps_Menu(){
	if [ "${WORKMODE}" != "In progress" ] && [ "${WORKMODE}" != "Image" ]
	then
		dialogOK "You should extract image files before continue..."
		return
	fi

	while [ true ]
	do
		dialogBT
		dialog --colors --backtitle "${DIALOGBT}" --title "Install system apps" --menu "Select:" 20 70 10 \
			"clean" "Remove system apps" \
			"busybox" "Install busybox" \
			"su" "Install su" \
			"apk" "Install apps as system" \
			"lib" "Restore lib from apk" \
			"fix" "Fix permissions" \
			"X" "Exit" 2> $tempfile
		case $? in
			0)
				s=`cat $tempfile`
				case $s in
					"busybox")
						installApps_BB
						;;
					"su")
						installApps_SU
						;;
					"clean")
						installApps_RemoveSelectedApk
						rm -rf ${tempdir}/*
						;;
					"apk")
						installApps_InstallSelectedApk
						rm -rf ${tempdir}/*
						;;
					"lib")
						installApps_ExtractSystemLibs
						SystemFixPermissions
						rm -rf ${tempdir}/*
						;;
					"fix")
						SystemFixPermissions
						rm -rf ${tempdir}/*
						;;
					"X")
						return
						;;
				esac
				;;
			*)
				return
				;;
		esac
	done
}

