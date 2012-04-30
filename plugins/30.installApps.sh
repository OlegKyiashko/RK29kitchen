#!/bin/bash
#set -vx

MenuAdd "System apps" "installApps_Menu"

installApps_BB(){
	SystemMount
	cd "$WORKDIR/Image"

	sudo cp "${PLUGINS}/installApps/bin/busybox" system/xbin/busybox 2>>"${LOGFILE}"

	for c in `cat "${PLUGINS}/installApps/bin/busybox.lst"`
	do
		dst="system/xbin/${c}"
		if [ -f "$dst" ] || [ -L "$dst" ]
		then
			sudo mv "$dst" "${dst}#"
		fi

		sudo ln -s /system/xbin/busybox ${dst} 2>>"${LOGFILE}"
	done

	SystemFixPermissions
}

installApps_SU(){
	SystemMount
	cd "$WORKDIR/Image"

	sudo mv system/bin/su "system/bin/su#" 2>/dev/null 
	sudo mv system/xbin/su "system/xbin/su#" 2>/dev/null

	sudo cp "${PLUGINS}/installApps/bin/su" system/xbin/su 2>>"${LOGFILE}"
	sudo cp "${PLUGINS}/installApps/bin/Superuser.apk" system/app/ 2>>"${LOGFILE}"

	SystemFixPermissions
}

installApps_ExtractSystemLibs(){
	pushd "${WORKDIR}/Image/system/app/" 2>/dev/null
	DirToArray "*.apk"
	n=${#FILEARRAY[@]}
	for (( i=0; i<${n}; i++ ))
	do
		f=${FILEARRAY[$i]}
		ApkLibExtract "$f"
		if [ ! -z "${APKLIBFILES}" ]
		then
			pushd "${APKLIBDIR}" 2>/dev/null
			sudo cp *.so "${WORKDIR}/Image/system/lib/"  2>>"${LOGFILE}"
			popd 2>/dev/null
		fi
	done
	popd 2>/dev/null
}

installApps_RemoveListApk(){
	SystemMount
	apklist=("${!1}")
	pushd "${WORKDIR}/Image/system/app/"
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
			pushd "${APKLIBDIR}" 2>/dev/null
			DirToArray "*.so"
			popd 2>/dev/null
			s=${#FILEARRAY[@]}
			for (( j=0; j<${s}; j++ ))
			do
				so="${FILEARRAY[$j]}"
				sudo rm "${WORKDIR}/Image/system//lib/$so" 2>>"${LOGFILE}"
			done
		fi
		sudo rm "${WORKDIR}/Image/system/app/$f" 2>>"${LOGFILE}"
	done
	popd

	installApps_ExtractSystemLibs
	SystemFixPermissions
}

installApps_RemoveAllApk(){
	SystemMount

	pushd "${WORKDIR}/Image/system/app/"
	ls -1|grep -f "${PLUGINS}/installApps/apkblacklist.txt" > "$tempfile"
	FileToArray "$tempfile"

	installApps_RemoveListApk FILEARRAY[@]
}

installApps_RemoveSelectedApk(){
	SystemMount

	pushd "${WORKDIR}/Image/system/app/"
	ls -1|grep -f "${PLUGINS}/installApps/apkblacklist.txt" > "$tempfile"
	FileToArray "$tempfile"
	bl=("${FILEARRAY[@]}")
	ls -1|grep -v -f "${PLUGINS}/installApps/apkwhitelist.txt"|grep -v -f "${PLUGINS}/installApps/apkblacklist.txt" > "$tempfile"
	FileToArray "$tempfile"
	gl=("${FILEARRAY[@]}")

	ListCheckboxDlg bl[@] gl[@] "Remove system apps" "Choose apk files:"
	if [ $? -eq 0 ]
	then
		installApps_RemoveListApk FILEARRAY[@]
	fi
}

installApps_InstallListApk(){
	SystemMount
	apklist=("${!1}")
	pushd "${PLUGINS}/installApps/apk"
	apklistsize=${#apklist[@]}
	for (( i=0; i<${apklistsize}; i++ ))
	do
		f=${apklist[$i]}
		sudo cp $f "${WORKDIR}/Image/system/app/"  2>>"${LOGFILE}"
	done
	popd
	installApps_ExtractSystemLibs
	SystemFixPermissions
}

installApps_InstallAllApk(){
	pushd "${PLUGINS}/installApps/apk"
	DirToArray "*apk"
	installApps_InstallListApk FILEARRAY[@]
	popd
}

installApps_InstallSelectedApk(){
	pushd "${PLUGINS}/installApps/apk"
	DirToArray "*apk"
	ListCheckboxDlg FILEARRAY[@] "" "Install apps as system" "Choose apk files:"
	if [ $? -eq 0 ]
	then
		installApps_InstallListApk FILEARRAY[@]
	fi
	popd
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
						;;
					"apk")
						installApps_InstallSelectedApk
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

